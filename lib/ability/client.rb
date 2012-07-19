require 'rest-client'
require 'builder'
require 'xmlsimple'

module Ability
  
  # Use Ability::Client.response.body to access the last raw response
  class Response
    attr_reader :body
    attr_accessor :error

    def initialize(body)
      @body = body
    end
  end

  # Ability::Client is a module for interacting with the Ability ACCESS API
  module Client

    API_ROOT = 'https://access.abilitynetwork.com/access'
    API_VERSION = 1

    def self.version
      Ability::VERSION
    end

    def self.user_agent
      "Ruby Ability Client/#{self.version}"
    end

    def self.user
      @user
    end

    def self.user=(user)
      @user = user
    end

    def self.password
      @password
    end

    def self.password=(password)
      @password = password
    end

    def self.facility_state
      @facility_state
    end

    def self.facility_state=(facility_state)
      @facility_state = facility_state
    end

    def self.line_of_business
      @line_of_business
    end

    def self.line_of_business=(line_of_business)
      @line_of_business = line_of_business
    end

    def self.ssl_ca_file
      @ssl_ca_file
    end

    def self.ssl_ca_file=(ssl_ca_file)
      @ssl_ca_file = ssl_ca_file
    end

    def self.ssl_client_cert
      @ssl_client_cert
    end

    def self.ssl_client_cert=(ssl_client_cert)
      @ssl_client_cert = ssl_client_cert
    end

    def self.ssl_client_key
      @ssl_client_key
    end

    def self.ssl_client_key=(ssl_client_key)
      @ssl_client_key = ssl_client_key
    end

    def self.response
      @response
    end

    def self.response=(response)
      @response = response
    end

    # Configure the client
    def self.configure(*args)
      opts = args_to_hash(*args)
      self.user = opts[:user]
      self.password = opts[:password]
      self.facility_state = opts[:facility_state]
      self.line_of_business = opts[:line_of_business]
      self.ssl_client_cert = opts[:ssl_client_cert]
      self.ssl_client_key = opts[:ssl_client_key]
      self.ssl_ca_file = opts[:ssl_ca_file]
    end

    # Return the results of a HIQA inquiry
    def self.hiqa_inquiry(*args)
      opts = args_to_hash(*args)
      details = opts[:details]

      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.instruct! :xml
      xml.hiqaRequest {
        xml.medicareMainframe {
          xml.application {
            xml.facilityState facility_state
            xml.lineOfBusiness line_of_business
          }
          xml.credential {
            xml.userId user
            xml.password password
          }
        }

        xml.details {
          if !details || details == :all || details.include?(:all)
            xml.detail 'ALL'
          else
            %w(1 2_3 4 5 6_7 8 9 10 11 12 13_N).each do |screen|
              xml.detail "Page#{screen}" if details.include?(:"page_#{screen}")
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
          xml.intermediaryNumber opts[:intermediary_number]
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
    def self.generate_password
      post(endpoint('password/generate'))
    end

    # Change a password or clerk password
    def self.change_password(new_password, *args)
      opts = args_to_hash(*args)

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
      self.password = new_password unless opts[:clerk]
    end
    
    private

    def self.endpoint(resource)
      "#{API_ROOT}/#{resource}"
    end

    # Convert XML to a hash
    def self.parse(xml)
      Ability::Parser.parse(xml)
    end

    def self.get(url)
      rest_exec(:get, url)
    end

    def self.post(url, payload = nil)
      rest_exec(:post, url, payload)
    end

    def self.rest_exec(method, url, payload = nil)
      opts = {
        :method => method,
        :url => url,
        :accept => :xml,
        :headers => {
          'User-Agent' => self.user_agent,
          'X-Access-Version' => API_VERSION,
          'Content-Type' => 'text/xml'
        }
      }

      if ssl_client_cert && ssl_client_key && ssl_ca_file
        opts.merge!({
          :ssl_ca_file => ssl_ca_file,
          :ssl_client_key => ssl_client_key,
          :ssl_client_cert => ssl_client_cert,
          :verify_ssl => true
        })
      end

      opts[:payload] = payload if payload

      RestClient::Request.execute(opts) do |response, request, result, &block|

        # make the last response available
        self.response = Ability::Response.new(response.body)

        # If an error code is in the response, raise a ResponseError exception.
        # Otherwise, return the response normally.
        if [400,401,404,405,415,500,503].include?(response.code)
          error = Ability::Error.generate(parse(response.body))
          self.response.error = error
          error.raise
        else
          response.return!(request, result, &block)
        end
      end
    end

    def self.args_to_hash(*args)
      Hash[*args.flatten]
    end

  end
end
