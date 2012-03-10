# Class for submitting a Claim Status Inquiry
module Ability
  module ClaimStatusInquiry

    class Request < Ability::Request
      attr_reader :user, :password, :service_id, :opts

      def initialize(user, password, service_id, opts)
        @user = user
        @password = password
        @service_id = service_id
        @opts = opts
      end

      def endpoint
        "https://access.abilitynetwork.com/portal/seapi/services/PPTNClaimStatusInquiry/#{service_id}"
      end

      def xml
        xml = Builder::XmlMarkup.new(:indent => 2)
        xml.instruct! :xml, :standalone => "yes"
        xml.claimStatusInquiryRequest(:xmlns => "http://www.visionshareinc.com/seapi/2008-09-22") {
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
          xml.searchCriteria {
            xml.npi opts[:npi]
            xml.hic opts[:hic]
            xml.fromDate opts[:from_date]
            xml.toDate opts[:to_date] if opts[:to_date]
            xml.hcpcs opts[:hcpcs] if opts[:hcpcs]
            xml.icn opts[:icn] if opts[:icn]
          }
        }
        xml.target!
      end
    end

    class Response < Ability::Response
      def parsed
        @parsed ||= doc.elements.to_a("//claimStatusInquiryResponse").inject({}) { |hsh, e|

          hsh[:beneficiary] = e.elements.to_a("beneficiary").map { |b|
            {
              :npi => b.elements.to_a("npi").first.text,
              :hic => b.elements.to_a("hic").first.text,
              :last_name => b.elements.to_a("lastName").first.text,
              :first_name => b.elements.to_a("firstName").first.text,
              :middle_initial => b.elements.to_a("middleInitial").first.text,
              :sex => b.elements.to_a("sex").first.text,
              :date_of_birth => Date.parse(b.elements.to_a("dateOfBirth").first.text),
              :trace_number => b.elements.to_a("traceNumber").first.text
            }
          }.first

          hsh[:claims] = e.elements.to_a("claims/claim").map { |c|
            {
              :icn => c.elements.to_a("icn").first.text,
              :category_code_1 => c.elements.to_a("categoryCode1").first.text,
              :status_code_1 => c.elements.to_a("statusCode1").first.text,
              :category_code_2 => c.elements.to_a("categoryCode2").first.text,
              :status_code_2 => c.elements.to_a("statusCode2").first.text,
              :total_billed => c.elements.to_a("totalBilledAmount").first.text.to_f,
              :paid_date => Date.parse(c.elements.to_a("paidDate").first.text),
              :total_paid => c.elements.to_a("totalPaidAmount").first.text.to_f,
              :check_number => c.elements.to_a("checkNumber").first.text,
              :check_date => Date.parse(c.elements.to_a("checkDate").first.text),
              :payment_method => c.elements.to_a("paymentMethod").first.text,
              :service_lines => c.elements.to_a("serviceLines/serviceLine").map { |l|
                {
                  :from_date => Date.parse(l.elements.to_a("fromDate").first.text),
                  :to_date => Date.parse(l.elements.to_a("toDate").first.text),
                  :hcpcs => l.elements.to_a("hcpcs").first.text,
                  :modifier_1 => l.elements.to_a("modifier1").first.text.to_i,
                  :modifier_2 => l.elements.to_a("modifier2").first.text.to_i,
                  :modifier_3 => l.elements.to_a("modifier3").first.text.to_i,
                  :modifier_4 => l.elements.to_a("modifier4").first.text.to_i,
                  :units_of_service => l.elements.to_a("unitsOfService").first.text.to_i,
                  :category_code => l.elements.to_a("categoryCode").first.text,
                  :status_code => l.elements.to_a("statusCode").first.text,
                  :billed_amount => l.elements.to_a("billedAmount").first.text.to_f,
                  :paid_amount => l.elements.to_a("paidAmount").first.text.to_f,
                  :control_number => l.elements.to_a("controlNumber").first.text
                }
              }
            }
          }

          # Result for inject
          hsh
        }
      end
    end
  end
end
