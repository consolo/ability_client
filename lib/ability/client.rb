require "rest-client"
require "builder"
require "xmlsimple"
require "openssl"

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

    def self.pem_key
      @pem_key
    end

    def self.pem_key=(pem_key)
      @pem_key = pem_key
    end

    def self.pkcs12_file
      @pkcs12_file
    end
    
    def self.pkcs12_file=(pkcs12_file)
      @pkcs12_file = pkcs12_file
    end

    def self.ssl_ca_file
      @ssl_ca_file
    end

    def self.ssl_client_cert
      @ssl_client_cert
    end

    def self.ssl_client_key
      @ssl_client_key
    end

    def self.ssl_ca_file
      @ssl_ca_file
    end

    # Configure the client
    def self.configure(opts)

      # If a config_file option was passed, configure
      # from a YML document
      if opts[:config_file]
        opts = YAML::load_file(config_file)
        return configure(opts)
      end

      @user          = opts[:user]
      @password      = opts[:password]
      @pem_key       = opts[:pem_key]
      @pkcs12_file   = opts[:pkcs12_file]
      @ssl_ca_file   = opts[:ssl_ca_file]
      @service_id    = opts[:service_id]

      # Setup SSL
      if @pkcs12_file
        cert = OpenSSL::PKCS12.new(File.read(pkcs12_file), pem_key)

        # Create the cert file if it doesn't exist
        if !File.exist?(ssl_ca_file)
          File.open(ssl_ca_file, "w") { |f|
            f.puts cert.ca_certs.collect(&:to_s).join("\n")
          }
        end

        @ssl_client_cert = cert.certificate
        @ssl_client_key = cert.key
        @ssl_ca_file = ssl_ca_file
      end
    end

    # Returns a list of services.
    def self.services
      parse(get(API_ROOT))["service"]
    end

    # Return the results of an eligibility inquiry
    def self.eligibility_inquiry(*args)
      opts = args_to_hash(*args)
      details = opts[:details]

      # TODO: wrap xml builder
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
          xml.detail "ALL" if details.include?(:all)
          xml.detail "FSS0_1751" if details.include?(:fss0_1751)
          xml.detail "FSS0_1752" if details.include?(:fss0_1752)
          xml.detail "FSS0_175J" if details.include?(:fss0_175J)
          xml.detail "FSS0_1755" if details.include?(:fss0_1755)
          xml.detail "FSS0_1756" if details.include?(:fss0_1756)
          xml.detail "FSS0_1757" if details.include?(:fss0_1757)
          xml.detail "FSS0_1758_175C" if details.include?(:fss0_1758_175C)
          xml.detail "FSS0_1759" if details.include?(:fss0_1759)
          xml.detail "FSS0_175K" if details.include?(:fss0_175K)
          xml.detail "FSS0_175L" if details.include?(:fss0_175L)
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
          "X-SEAPI-Version" => SEAPI_VERSION
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
