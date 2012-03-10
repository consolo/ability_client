module Ability
  module PasswordGenerate
    class Request < Ability::Request
      attr_reader :service_id

      def initialize(service_id)
        @service_id = service_id
      end

      def endpoint
        "https://access.abilitynetwork.com/portal/seapi/services/PasswordGenerate/#{service_id}"
      end
    end
  end
end
