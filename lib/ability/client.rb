require "rest-client"
require "builder"
require "xmlsimple"

module Ability

  # Ability::Client is a module for interacting with the Ability ACCESS API
  module Client

    SEAPI_VERSION = 1
    API_ROOT      = "https://access.abilitynetwork.com/portal/seapi/services"

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

    def self.service_id
      @service_id
    end

    def self.service_id=(service_id)
      @service_id = service_id
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
      @ssl_client_cert
    end

    def self.ssl_client_key
      @ssl_client_key
    end

    def self.ssl_client_key=(ssl_client_key)
      @ssl_client_key = ssl_client_key
    end

    # Configure the client
    def self.configure(opts)
      @user             = opts[:user]
      @password         = opts[:password]
      @ssl_ca_file      = opts[:ssl_ca_file]
      @service_id       = opts[:service_id]
      @ssl_client_cert  = opts[:ssl_client_cert]
      @ssl_client_key   = opts[:ssl_client_key]
      @ssl_ca_file      = opts[:ssl_ca_file]
    end

    # Returns a list of services.
    def self.services
      parse(get(API_ROOT))["service"]
    end

    # Return the results of an eligibility inquiry
    def self.eligibility_inquiry(*args)
      opts = args_to_hash(*args)
      details = opts[:details]

      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.instruct! :xml
      xml.eligibilityInquiryRequest(:xmlns => "http://www.visionshareinc.com/seapi/2008-09-22") {
        xml.medicareMainframe {
          xml.application {
            xml.facilityState opts[:facility_state]
            xml.lineOfBusiness opts[:line_of_business]
          }
          xml.credential {
            xml.userId user
            xml.password password
          }
        }
        xml.details {
          if !details || details == :all || details.include?(:all)
            xml.detail "ALL"
          else
            %w(1751 1752 175J 1755 1756 1757 1758_175C 1759 175K 175L).each do |screen|
              xml.detail "FSS0_#{screen}" if details.include?(:"fss0_#{screen}")
            end
          end
        }
        if beneficiary = opts[:beneficiary]
          xml.beneficiary {
            xml.hic beneficiary[:hic]
            xml.lastName beneficiary[:last_name]
            xml.firstName beneficiary[:first_name]
            xml.sex beneficiary[:sex]
            xml.dateOfBirth beneficiary[:date_of_birth]
          }
        end
      }
    
      parse(post(endpoint("DDEEligibilityInquiry"), xml.target!))["eligibility"]
    end

    # Generate a password
    def self.generate_password(*args)
      opts = args_to_hash(*args)
      post(endpoint("PasswordGenerate"))
    end

    # Change a password or clerk password
    def self.change_password(new_password, *args)
      opts = args_to_hash(*args)

      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.instruct! :xml, :standalone => "yes"
      xml.passwordChangeRequest(:xmlns => "http://www.visionshareinc.com/seapi/2008-09-22") {
        xml.medicareMainframe {
          xml.application { 
            xml.facilityState opts[:facility_state]
            xml.lineOfBusiness opts[:line_of_business]
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

      post(endpoint("PasswordChange"), xml.target!)

      # Change client password unless clerk password is being changed
      self.password = new_password unless opts[:clerk]
    end
    
    private

    def self.endpoint(resource)
      "#{API_ROOT}/#{resource}/#{service_id}"
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
          "User-Agent" => self.user_agent,
          "X-SEAPI-Version" => SEAPI_VERSION,
          "Content-Type" => "text/xml"
        }
      }

      if @ssl_client_cert && @ssl_client_key && @ssl_ca_file
        opts.merge!({
          :ssl_ca_file => ssl_ca_file,
          :ssl_client_key => ssl_client_key,
          :ssl_client_cert => ssl_client_cert,
          :verify_ssl => true
        })
      end

      opts[:payload] = payload if payload

      RestClient::Request.execute(opts) do |response, request, result, &block|
        # If an error code is in the response, raise a ResponseError exception.
        # Otherwise, return the response normally.
        if [400,401,404,405,415,500,503].include?(response.code)
          error = Ability::Error.generate(parse(response.body))
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
