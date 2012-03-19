module Ability
  module EligibilityInquiry
    
    class Request < Ability::Request
      attr_reader :user, :password, :service_id, :opts

      def initialize(user, password, service_id, opts)
        @user = user
        @password = password
        @service_id = service_id
        @opts = opts
      end

      def resource_name
        "DDEEligibilityInquiry"
      end

      def xml
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
        xml.target!
      end
    end

    class Response < Ability::Response
      include Ability::Helpers::XmlHelpers
      include Ability::Helpers::EligibilityHelpers

      def parsed
        return @parsed if @parsed

        details = opts[:details]
        all = (details == :all)

        # Eligibility element
        eligibility = elem(doc, "//eligibilityInquiryResponse/eligibility")

        # Eligibility data
        e = {}

        # Screen 1751
        if (all || details.include?(:fss0_1751)) && screen_1751 = elem(eligibility, "screen1751")
          e[:screen_1751] = {}

          e[:screen_1751][:beneficiary] = process_beneficiary(elem(screen_1751, "beneficiary"))

          if current_entitlement = elem(screen_1751, "currentEntitlement")
            e[:screen_1751][:current_entitlement] = process_entitlement(current_entitlement)
          end

          if current_benefit_period = elem(screen_1751, "currentBenefitPeriodData")
            e[:screen_1751][:current_benefit_period] = process_benefit_period(current_benefit_period)
          end

          if psychiatric = elem(screen_1751, "psychiatric")
            e[:screen_1751][:psychiatric] = process_psychiatric(psychiatric)
          end

          if reason_codes = elem(screen_1751, "reasonCodes")
            e[:screen_1751][:reason_codes] = process_reason_codes(reason_codes)
          end
        end # end screen_1751

        # Screen 1752
        if (all || details.include?(:fss0_1752)) && screen_1752 = elem(eligibility, "screen1752")
          e[:screen_1752] = {}

          if part_b = elem(screen_1752, "partBData")
            e[:screen_1752][:part_b] = process_part_b(part_b)
          end

          if mco_plans = elem(screen_1752, "mcoPlans")
            e[:screen_1752][:mco_plans] = mco_plans.elements.to_a("mcoPlan").map { |mco_plan|
              process_mco_plan(mco_plan)
            }
          end

          if hospice = elem(screen_1752, "hospiceData")
            e[:screen_1752][:hospice] = process_hospice(hospice)
          end
        end # end screen_1752

        # Screen 175J
        if (all || details.include?(:fss0_175J)) && screen_175J = elem(eligibility, "screen175J")
          e[:screen_175J] = {}

          preventative_services = screen_175J.elements.to_a("preventativeService")
          if preventative_services && !preventative_services.empty?
            e[:screen_175J][:preventative_services] = process_preventative_services(preventative_services)
          end
        end # end screen 175J

        # Screen 1755
        if (all || details.include?(:fss0_1755)) && screen_1755 = elem(eligibility, "screen1755")
          e[:screen_1755] = {}
          
          if current_entitlement = elem(screen_1755, "currentEntitlement")
            e[:screen_1755][:current_entitlement] = process_entitlement(current_entitlement)
          end

          if prior_entitlement = elem(screen_1755, "priorEntitlement")
            e[:screen_1755][:prior_entitlement] = process_entitlement(prior_entitlement)
          end

          if lifetime = elem(screen_1755, "lifetimeData")
            e[:screen_1755][:lifetime] = process_lifetime(lifetime)
          end

          if current_benefit_period = elem(screen_1755, "currentBenefitPeriodData")
            e[:screen_1755][:current_benefit_period] = process_benefit_period(current_benefit_period)
          end

          if prior_benefit_period = elem(screen_1755, "priorBenefitPeriodData")
            e[:screen_1755][:prior_benefit_period] = process_benefit_period(prior_benefit_period)
          end

          if current_part_b = elem(screen_1755, "currentPartBData")
            e[:screen_1755][:current_part_b] = process_temporal_part_b(current_part_b)
          end

          if prior_part_b = elem(screen_1755, "priorPartBData")
            e[:screen_1755][:prior_part_b] = process_temporal_part_b(prior_part_b)
          end
        end # end screen_1755

        # Screen 1756
        if (all || details.include?(:fss0_1756)) && screen_1756 = elem(eligibility, "screen1756")

          e[:screen_1756] = {}

          if data_indicator = elem(screen_1756, "dataIndicator")
            e[:screen_1756][:data_indicator] = data_indicator.text
          end

          if plan_enrollment_code = elem(screen_1756, "planEnrollmentCode")
            e[:screen_1756][:plan_enrollment_code] = plan_enrollment_code.text.to_i
          end

          if current_mco_plan = elem(screen_1756, "currentMcoPlan")
            e[:screen_1756][:current_mco_plan] = process_mco_plan(current_mco_plan)
          end

          if prior_mco_plan = elem(screen_1756, "priorMcoPlan")
            e[:screen_1756][:prior_mco_plan] = process_mco_plan(prior_mco_plan)
          end

          if other_entitlement_code = elem(screen_1756, "otherEntitlementCode")
            e[:screen_1756][:other_entitlement_code] = other_entitlement_code.text
          end

          if other_entitlement_date = elem(screen_1756, "otherEntitlementDate")
            e[:screen_1756][:other_entitlement_date] = Date.parse(other_entitlement_date.text)
          end

          if esrd_code = elem(screen_1756, "esrdCode")
            e[:screen_1756][:esrd_code] = esrd_code.text.to_i
          end

          if esrd_date = elem(screen_1756, "esrdDate")
            e[:screen_1756][:esrd_date] = Date.parse(esrd_date.text)
          end

          if psychiatric = elem(screen_1756, "psychiatric")
            e[:screen_1756][:psychiatric] = process_psychiatric(psychiatric)
          end
        end # end screen_1756

        # Screen 1757
        if (all || details.include?(:fss0_1757)) && screen_1757 = elem(eligibility, "screen1757")

          e[:screen_1757] = {}

          if transplants = elem(screen_1757, "transplants")
            e[:screen_1757][:transplants] = transplants.elements.to_a("transplant").map { |transplant|
              process_transplant(transplant)
            }
          end

          if home_health_episode_dates = elem(screen_1757, "homeHealthEpisodeDates")
            e[:screen_1757][:home_health_episode_dates] = process_home_health_episode_dates(home_health_episode_dates)
          end
        end # end screen_1757

        # Screen 1758_175C
        if (all || details.include?(:fss0_1758_175C)) && screen_1758_175C = elem(eligibility, "screen1758_175C")

          e[:screen_1758_175C] = {}

          (1..4).each do |n|
            if period = elem(screen_1758_175C, "period#{n}")
              e[:screen_1758_175C][:"period_#{n}"] = process_hospice(period)
            end
          end
        end # end screen_1758_175C

        # Screen 175K
        if (all || details.include?(:fss0_175K)) && screen_175K = elem(eligibility, "screen175K")
          
          e[:screen_175K] = {}

          if counseling_periods = elem(screen_175K, "counselingPeriods")
            e[:screen_175K][:counseling_periods] = counseling_periods.elements.to_a("period").map { |period|
              process_period(period)
            }
          end

          if counseling_sessions = elem(screen_175K, "counselingSessions")
            e[:screen_175K][:counseling_sessions] = counseling_sessions.elements.to_a("session").map { |session|
              process_session(session)
            }
          end
        end # end screen_175K

        # Screen 1759
        if (all || details.include?(:fss0_1759)) && screen_1759 = elem(eligibility, "screen1759")

          e[:screen_1759] = {}

          e[:screen_1759][:msps] = screen_1759.elements.to_a("mspData").map { |msp|
            process_msp(msp)
          }
        end # end screen_1759

        # Screen 175L
        if (all || details.include?(:fss0_175L)) && screen_175L = elem(eligibility, "screen175L")
          
          e[:screen_175L] = {}

          e[:screen_175L][:home_health_certifications] = screen_175L.elements.to_a("homeHealthCertification").map { |home_health_certification|
            process_home_health_certification(home_health_certification)
          }
        end # end screen 175L

        @parsed = e
        return @parsed
      end
    end
  end
end
