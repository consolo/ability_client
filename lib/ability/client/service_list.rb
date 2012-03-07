# Class for submitting a request for a Service List
class Ability::Client::ServiceList

  SERVICES_ENDPOINT = "https://portal.abilitynetwork.com/portal/services"

  def initialize(client)
    @client = client
  end

  def submit
    doc = @client.parse_xml(@client.get(SERVICES_ENDPOINT))
    doc.elements.to_a("//services/service").map do |e|
      {
        :id => e.attributes["id"].to_i,
        :type => e.attributes["type"],
        :name => e.elements.to_a("name").first.text,
        :uri => e.elements.to_a("uri").first.text
      }
    end
  end
end
