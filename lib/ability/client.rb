require "rest-client"
require "builder"
require "rexml/document"

# Class for interacting with the ABILITY ACCESS API.
class Ability::Client

  attr_accessor :ssl_client_cert,
                :ssl_client_key,
                :ssl_ca,
                :user,
                :password,
                :facility_state,
                :line_of_business,
                :service_id

  def self.version
    Ability::VERSION
  end

  def initialize(*args)
    opts = args_to_hash(*args)
    @ssl_client_cert = opts[:ssl_client_cert]
    @ssl_client_key = opts[:ssl_client_key]
    @ssl_ca = opts[:ssl_ca]
    @user = opts[:user]
    @password = opts[:password]
    @facility_state = opts[:facility_state]
    @line_of_business = opts[:line_of_business]
    @service_id = opts[:service_id]
  end

  # Returns a list of services.
  def services
    service_list = Ability::Client::ServiceList.new(self)
    service_list.submit
  end

  # Returns the results of a claim inquiry search
  def claim_inquiry(service_id, *args)
    opts = args_to_hash(*args)
    claim_inquiry = Ability::Client::ClaimInquiry.new(self, service_id, opts)
    claim_inquiry.submit
  end

  # Return the results of an eligibility inquiry
  def eligibility_inquiry(service_id, *args)
    opts = args_to_hash(*args)
    eligibility_inquiry = Ability::Client::EligibilityInquiry.new(self, service_id, opts)
    eligibility_inquiry.submit
  end

  # Return the results of a claim status inquiry
  def claim_status_inquiry(service_id, *args)
    opts = args_to_hash(*args)
    claim_status_inquiry = Ability::Client::ClaimStatusInquiry.new(self, service_id, opts)
    claim_status_inquiry.submit
  end

  # Generate a password
  def generate_password(service_id)
    generate_password_endpoint = "https://access.abilitynetwork.com/portal/seapi/services/PasswordGenerate/#{service_id}"
    post(generate_password_endpoint)
  end

  # Change a password or clerk password
  def change_password(service_id, new_password, *args)
    opts = args_to_hash(*args)
    change_password = Ability::Client::ChangePassword.new(self, service_id, new_password, opts)
    change_password.submit
  end
  
  def parse_xml(raw)
    REXML::Document.new(raw)
  end

  def get(url)
    rest_exec(:get, url)
  end

  def post(url, payload = nil)
    rest_exec(:post, url, payload)
  end

  def rest_exec(method, url, payload = nil)
    rest_client_opts = {
      :method => method,
      :url => url,
      :accept => :xml
    }

    rest_client_opts[:payload] = payload if payload

    RestClient::Request.execute(rest_client_opts)
  end

  private

  def args_to_hash(*args)
    Hash[*args.flatten]
  end

end
