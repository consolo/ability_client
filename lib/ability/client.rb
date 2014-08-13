require 'rest-client'
require 'builder'
require 'xmlsimple'

module Ability

  HIQA_SCREENS = {
    beneficiary_information: 'BeneficiaryInformation',
    hospice_information: 'HospiceInformation',
    home_health_benefit_periods: 'HomeHealthBenefitPeriods',
    home_health_episodes: 'HomeHealthEpisodes',
    screening_information: 'ScreeningInformation',
    preventative_services: 'PreventativeServices',
    smoking_cessation: 'SmokingCessation',
    rehabilitation_sessions: 'RehabilitationSessions',
    home_health_certifications: 'HomeHealthCertifications',
    telehealth_services: 'TelehealthServices',
    behavioral_services: 'BehavioralServices',
    high_intensity_behavioral_counseling: 'HighIntensityBehavioralCounseling',
    medicare_secondary_payers: 'MedicareSecondaryPayers'
  }
  
  # Use Ability::Client.response.body to access the last raw response
  class Response
    attr_reader :body, :error

    def initialize(body)
      @body = body
    end
  end

  # Ability::Client is a module for interacting with the Ability ACCESS API
  class Client
    attr_accessor :response, :user, :password, :facility_state

    API_ROOT = 'https://access.abilitynetwork.com/access'
    API_VERSION = 1
    USER_AGENT = "Ruby Ability Client/#{Ability::VERSION}"

    # Configure the client
    def self.configure(opts)
      @@line_of_business = opts[:line_of_business]
      @@ssl_client_cert = opts[:ssl_client_cert]
      @@ssl_client_key = opts[:ssl_client_key]
      @@ssl_ca_file = opts[:ssl_ca_file]
      @@timeout = opts[:timeout]
      @@open_timeout = opts[:open_timeout]
    end

    def initialize(user, password, facility_state)
      @user = user
      @password = password
      @facility_state = facility_state
    end

    # Return the results of a HIQA inquiry
    def hiqa_inquiry(opts = {})
      details = opts[:details]

      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.instruct! :xml
      xml.hiqaRequest {
        xml.medicareMainframe {
          xml.application {
            xml.facilityState @facility_state
            xml.lineOfBusiness @@line_of_business
          }
          xml.credential {
            xml.userId @user
            xml.password @password
          }
        }

        xml.details {
          if !details || details == :all || details.include?(:all)
            xml.detail 'ALL'
          else
            details.each do |detail|
              xml.detail HIQA_SCREENS[detail]
            end
          end
        }

        xml.searchCriteria {
          xml.hic opts[:hic]
          xml.lastName opts[:last_name][0,6]
          xml.firstInitial opts[:first_initial]
          xml.dateOfBirth opts[:date_of_birth].strftime('%Y-%m-%d')
          xml.sex opts[:sex]
          xml.requestorId opts[:requestor_id]
          xml.intermediaryNumber opts[:intermediary_number][0,5]
          xml.npiIndicator opts[:npi_indicator] if opts[:npi_indicator]
          xml.providerId opts[:provider_id]
          xml.hostId opts[:host_id] if opts[:host_id]
          xml.applicableDate Date.strptime('%Y-%m-%d', opts[:applicable_date]) if opts[:applicable_date]
          xml.reasonCode opts[:reason_code] if opts[:reason_code]
        }
      }

      parse(post(endpoint('cwf/hiqa'), xml.target!))
    end

    # Generate a password
    def generate_password
      post(endpoint('password/generate'))
    end

    # Change a password or clerk password
    def change_password(new_password, opts = {})
      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.instruct! :xml, :standalone => "yes"
      xml.passwordChangeRequest {
        xml.medicareMainframe {
          xml.application { 
            xml.facilityState facility_state
            xml.lineOfBusiness line_of_business
          }
          xml.credential {
            xml.userId user
            xml.password password
          }
          if clerk = opts[:clerk]
            xml.clerkCredential {
              xml.userId clerk[:user]
              xml.password clerk[:password]
            }
          end
        }
        xml.newPassword new_password
      }

      post(endpoint('password/change'), xml.target!)

      # Change client password unless clerk password is being changed
      @password = new_password unless opts[:clerk]
    end
    
    private

    def endpoint(resource)
      "#{API_ROOT}/#{resource}"
    end

    # Convert XML to a hash
    def parse(xml)
      Ability::Parser.parse(xml)
    end

    def get(url)
      rest_exec(:get, url)
    end

    def post(url, payload = nil)
      rest_exec(:post, url, payload)
    end

    def rest_exec(method, url, payload = nil)
      opts = build_rest_client_opts(method, url, payload)
      make_request(opts)
    rescue Timeout::Error, RestClient::RequestTimeout
      raise Ability::TransmissionError, "Connection to server timed out @ #{url}"
    rescue Errno::ECONNREFUSED
      raise Ability::TransmissionError, "Connection to server was refused @ #{url}"
    end

    def make_request(opts)
      RestClient::Request.execute(opts) do |response, request, result, &block|
        # make the last response available
        @response = Ability::Response.new(response.body)

        # If an error code is in the response, raise a ResponseError exception.
        # Otherwise, return the response normally.
        if [400,401,404,405,415,500,503].include?(response.code)
          error = Ability::Error.generate(parse(@response.body))
          @response.error = error
          error.raise
        else
          response.return!(request, result, &block)
        end
      end
    end

    def build_rest_client_opts(method, url, payload)
      opts = {
        method: method,
        url: url,
        accept: :xml,
        headers: {
          'User-Agent' => USER_AGENT,
          'X-Access-Version' => API_VERSION,
          'Content-Type' => 'text/xml'
        },
        timeout: @@timeout,
        open_timeout: @@open_timeout
      }

      if @@ssl_client_cert && @@ssl_client_key && @@ssl_ca_file
        opts.merge!({
          ssl_ca_file: @@ssl_ca_file,
          ssl_client_key: @@ssl_client_key,
          ssl_client_cert: @@ssl_client_cert,
          verify_ssl: true
        })
      end

      opts[:payload] = payload if payload
      opts
    end

  end
end
