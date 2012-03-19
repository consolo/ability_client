module Ability
  module PasswordGenerate
    class Request < Ability::Request
      attr_reader :service_id

      def initialize(service_id)
        @service_id = service_id
      end

      def resource_name
        "PasswordGenerate"
      end
    end
  end
end
