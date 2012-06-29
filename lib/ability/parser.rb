module Ability
  module Parser

    def self.parse(raw)
      XmlSimple.xml_in(raw, parsing_options)
    end

    def self.parsing_options
      {
        
        # The following elements must always be returned as an array
        "ForceArray" => [
          "reasonCode",
          "mcoPlan",
          "preventativeService",
          "transplant",
          "period",
          "session",
          "mspData",
          "homeHealthCertification",
          "service",
          "detail",
          "hospiceBenefitPeriod"
        ],

        "SuppressEmpty" => nil
      }
    end
  end
end
