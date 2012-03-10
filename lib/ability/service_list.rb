module Ability
  module ServiceList

    class Request < Ability::Request
      def endpoint
        "https://portal.abilitynetwork.com/portal/services"
      end
    end
    
    class Response < Ability::Response
      def parsed
        @parsed ||= doc.elements.to_a("//services/service").map do |e|
          {
            :id => e.attributes["id"].to_i,
            :type => e.attributes["type"],
            :name => e.elements.to_a("name").first.text,
            :uri => e.elements.to_a("uri").first.text
          }
        end
      end
    end

  end
end
