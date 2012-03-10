require "rest-client"
require "builder"
require "rexml/document"

# Class for interacting with the ABILITY ACCESS API.
class Ability::Client
  include Ability::Helpers::XmlHelpers

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

  def initialize(username, password, *args)
    opts = args_to_hash(*args)
    @ssl_client_cert = opts[:ssl_client_cert]
    @ssl_client_key = opts[:ssl_client_key]
    @ssl_ca = opts[:ssl_ca]
    @user = username
    @password = password
    @facility_state = opts[:facility_state]
    @line_of_business = opts[:line_of_business]
    @service_id = opts[:service_id]
  end

  # Returns a list of services.
  def services
    request = Ability::ServiceList::Request.new
    response = Ability::ServiceList::Response.new(xml(get(request.endpoint)))
    response.parsed
  end

  # Returns the results of a claim inquiry search
  def claim_inquiry(service_id, *args)
    opts = args_to_hash(*args)
    request = Ability::ClaimInquiry::Request.new(user, password, service_id, opts)
    doc = xml(post(request.endpoint, request.xml))
    response = Ability::ClaimInquiry::Response.new(doc, opts)
    response.parsed
  end

  # Return the results of an eligibility inquiry
  def eligibility_inquiry(service_id, *args)
    opts = args_to_hash(*args)
    request = Ability::EligibilityInquiry::Request.new(user, password, service_id, opts)
    doc = xml(post(request.endpoint, request.xml))
    response = Ability::EligibilityInquiry::Response.new(doc, opts)
    response.parsed
  end

  # Return the results of a claim status inquiry
  def claim_status_inquiry(service_id, *args)
    opts = args_to_hash(*args)
    request = Ability::ClaimStatusInquiry::Request.new(user, password, service_id, opts)
    doc = xml(post(request.endpoint, request.xml))
    response = Ability::ClaimStatusInquiry::Response.new(doc, opts)
    response.parsed
  end

  # Generate a password
  def generate_password(service_id)
    request = Ability::PasswordGenerate::Request.new(service_id)
    post(request.endpoint)
  end

  # Change a password or clerk password
  def change_password(service_id, new_password, *args)
    opts = args_to_hash(*args)
    request = Ability::ChangePassword::Request.new(user, password, service_id, new_password, opts)
    post(request.endpoint, request.xml)

    # Change client password unless clerk password is being changed
    @password = new_password unless opts[:clerk]
  end
  
  private

  def xml(raw)
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

    RestClient::Request.execute(rest_client_opts) do |response, request, result, &block|
      if [400,401,404,405,415,500,503].include?(response.code)
        e = Error::Response.new(response.body)
        e.raise
      else
        response.return!(request, result, &block)
      end
    end
  end

  def args_to_hash(*args)
    Hash[*args.flatten]
  end

end
