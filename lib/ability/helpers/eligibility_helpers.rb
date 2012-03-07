module Ability
  module Helpers
    module EligibilityHelpers
      include Ability::Helpers::XmlHelpers

      # Process a beneficiary element
      def process_beneficiary(element)

        b = {}

        b[:hic] = elem_text(element, "hic")
        b[:last_name] = elem_text(element, "lastName")
        b[:first_name] = elem_text(element, "firstName")

        if middle_initial = elem(element, "middleInitial")
          b[:middle_initial] = middle_initial.text
        end

        b[:sex] = elem_text(element, "sex")
        b[:date_of_birth] = Date.parse(elem_text(element, "dateOfBirth"))

        if date_of_death = elem(element, "dateOfDeath")
          b[:date_of_death] = Date.parse(date_of_death.text)
        end

        if address_1 = elem(element, "address1")
          b[:address_1] = address_1.text
        end

        if address_2 = elem(element, "address2")
          b[:address_2] = address_2.text
        end

        if address_3 = elem(element, "address3")
          b[:address_3] = address_3.text
        end

        if zip_code = elem(element, "zipCode")
          b[:zip_code] = zip_code.text
        end

        return b
      end

      # Process an "entitlementType" element
      def process_entitlement(element)

        e = {}

        part_a_effective_date = elem(element, "partAEffectiveDate")
        part_a_termination_date = elem(element, "partATerminationDate")

        if part_a_effective_date || part_a_termination_date
          e[:part_a] = {}
          
          if part_a_effective_date
            e[:part_a][:effective_date] = Date.parse(part_a_effective_date.text)
          end

          if part_a_termination_date
            e[:part_a][:termination_date] = Date.parse(part_a_termination_date.text)
          end
        end

        part_b_effective_date = elem(element, "partBEffectiveDate")
        part_b_termination_date = elem(element, "partBTerminationDate")

        if part_b_effective_date || part_b_termination_date
          e[:part_b] = {}

          if part_b_effective_date
            e[:part_b][:effective_date] = Date.parse(part_b_effective_date.text)
          end

          if part_b_termination_date
            e[:part_b][:termination_date] = Date.parse(part_b_termination_date.text)
          end
        end

        return e
      end

      # Process a psychiatric element
      def process_psychiatric(element)
        p = {}

        if remaining_days = elem(element, "daysRemaining")
          p[:remaining_days] = remaining_days.text.to_i
        end

        if pre_entitlement_days_used = elem(element, "preEntitlementDaysUsed")
          p[:pre_entitlement_days_used] = pre_entitlement_days_used.text.to_i
        end

        if discharge_date = elem(element, "dischargeDate")
          p[:discharge_date] = Date.parse(discharge_date.text)
        end

        if interim_date_indicator = elem(element, "interimDateIndicator")
          p[:interim_date_indicator] = interim_date_indicator.text
        end

        return p
      end

      # Process reason codes
      def process_reason_codes(element)
        element.elements.to_a("reasonCode").map { |rc| rc.text }
      end

      # Process Part B
      def process_part_b(element)

        p = {}

        if service_year = elem(element, "serviceYear")
          p[:service_year] = service_year.text
        end

        if medical_expense = elem(element, "medicalExpense")
          p[:medical_expense] = medical_expense.text.to_f
        end

        if remaining_blood_pints = elem(element, "bloodPintsRemaining")
          p[:remaining_blood_pints] = remaining_blood_pints.text.to_i
        end

        if psychiatric_expense = elem(element, "psychiatricExpense")
          p[:psychiatric_expense] = psychiatric_expense.text.to_f
        end

        return p
      end

      # Process an element of the "mcoPlanType"
      def process_mco_plan(element)
        m = {}

        if type = elem(element, "type")
          m[:type] = type.text
        end

        if code = elem(element, "idCode")
          m[:code] = code.text
        end

        if option_code = elem(element, "optionCode")
          m[:option_code] = option_code.text
        end
        
        if effective_date = elem(element, "effectiveDate")
          m[:effective_date] = Date.parse(effective_date.text)
        end

        if termination_date = elem(element, "terminationDate")
          m[:termination_date] = Date.parse(termination_date.text)
        end

        return m
      end

      # Process an element of the "hospiceDataType"
      def process_hospice(element)
        h = {}

        if period = elem(element, "period")
          h[:period] = period.text.to_i
        end

        if first_provider_start_date = elem(element, "firstProviderStartDate")
          h[:first_provider_start_date] = Date.parse(first_provider_start_date.text)
        end
        
        if first_provider_id = elem(element, "firstProviderId")
          h[:first_provider_id] = first_provider_id.text
        end

        if first_intermediary_id = elem(element, "firstIntermediaryId")
          h[:first_intermediary_id] = first_intermediary_id.text
        end

        if first_owner_change_start_date = elem(element, "firstOwnerChangeStartDate")
          h[:first_owner_change_start_date] = Date.parse(first_owner_change_start_date.text)
        end

        if first_owner_change_provider_id = elem(element, "firstOwnerChangeProviderId")
          h[:first_owner_change_provider_id] = first_owner_change_provider_id.text
        end

        if first_owner_change_intermediary_id = elem(element, "firstOwnerChangeIntermediaryId")
          h[:first_owner_change_intermediary_id] = first_owner_change_intermediary_id.text
        end

        if second_provider_start_date = elem(element, "secondProviderStartDate")
          h[:second_provider_start_date] = Date.parse(second_provider_start_date.text)
        end

        if second_provider_id = elem(element, "secondProviderId")
          h[:second_provider_id] = second_provider_id.text
        end

        if second_intermediary_id = elem(element, "secondIntermediaryId")
          h[:second_intermediary_id] = second_intermediary_id.text
        end

        if second_owner_change_start_date = elem(element, "secondOwnerChangeStartDate")
          h[:second_owner_change_start_date] = Date.parse(second_owner_change_start_date.text)
        end

        if second_owner_change_provider_id = elem(element, "secondOwnerChangeProviderId")
          h[:second_owner_change_provider_id] = second_owner_change_provider_id.text
        end

        if second_owner_change_intermediary_id = elem(element, "secondOwnerChangeIntermediaryId")
          h[:second_owner_change_intermediary_id] = second_owner_change_intermediary_id.text
        end

        if termination_date = elem(element, "terminationDate")
          h[:termination_date] = Date.parse(termination_date.text)
        end

        if first_billed_date = elem(element, "firstBilledDate")
          h[:first_billed_date] = Date.parse(first_billed_date.text)
        end

        if last_billed_date = elem(element, "lastBilledDate")
          h[:last_billed_date] = Date.parse(last_billed_date.text)
        end

        if days_billed = elem(element, "daysBilled")
          h[:days_billed] = days_billed.text.to_i
        end

        if revocation_indicator = elem(element, "revocationIndicator")
          h[:revocation_indicator] = revocation_indicator.text.to_i
        end

        return h
      end

      # Process an array of PrevenativeService
      def process_preventative_services(elements)
        elements.map { |preventative_service|
          {
            :category => elem_text(preventative_service, "category"),
            :hcpcs => elem_text(preventative_service, "hcpcs"),
            :technical_date => elem_text(preventative_service, "technicalDate"),
            :professional_date => elem_text(preventative_service, "professionalDate")
          }
        }
      end

      # Process a "lifetimeData" element
      def process_lifetime(element)
        l = {}

        if remaining_reserve_days = elem(element, "reserveDaysRemaining")
          l[:remaining_reserve_days] = remaining_reserve_days.text.to_i
        end

        if psychiatric_days_available = elem(element, "psychiatricDaysAvailable")
          l[:psychiatric_days_available] = psychiatric_days_available.text.to_i
        end

        return l
      end

      # Process an element of the "benefitPeriodDataType"
      def process_benefit_period(element)
        p = {}

        if first_bill_date = elem(element, "firstBillDate")
          p[:first_bill_date] = Date.parse(first_bill_date.text)
        end

        if last_bill_date = elem(element, "lastBillDate")
          p[:last_bill_date] = Date.parse(last_bill_date.text)
        end

        if hospital_full_days = elem(element, "hospitalFullDays")
          p[:hospital_full_days] = hospital_full_days.text.to_i
        end

        if hospital_part_days = elem(element, "hospitalPartDays")
          p[:hospital_part_days] = hospital_part_days.text.to_i
        end

        if snf_full_days = elem(element, "snfFullDays")
          p[:snf_full_days] = snf_full_days.text.to_i
        end

        if snf_part_days = elem(element, "snfPartDays")
          p[:snf_part_days] = snf_part_days.text.to_i
        end

        if remaining_inpatient_deductible = elem(element, "inpatientDeductibleRemaining")
          p[:remaining_inpatient_deductible] = remaining_inpatient_deductible.text.to_f
        end

        if remaining_blood_pints = elem(element, "bloodPintsRemaining")
          p[:remaining_blood_pints] = remaining_blood_pints.text.to_i
        end

        return p
      end

      # Process "currentPartBData" and "priorPartBData" elements
      def process_temporal_part_b(element)
        p = {}

        if service_year = elem(element, "serviceYear")
          p[:service_year] = service_year.text
        end

        if remaining_blood_pints = elem(element, "bloodPintsRemaining")
          p[:remaining_blood_pints] = remaining_blood_pints.text.to_i
        end

        if remaining_psychiatric = elem(element, "psychiatricRemaining")
          p[:remaining_psychiatric] = remaining_psychiatric.text.to_f
        end

        if remaining_physical_therapy = elem(element, "physicalTherapyRemaining")
          p[:remaining_physical_therapy] = remaining_physical_therapy.text.to_f
        end

        if remaining_occupational_therapy = elem(element, "occupationalTherapyRemaining")
          p[:remaining_occupational_therapy] = remaining_occupational_therapy.text.to_f
        end

        return p
      end

      # Process a "transplant" element
      def process_transplant(element)
        t = {}

        if covered = elem(element, "covered")
          t[:covered] = (covered.text == "true")
        end

        if type = elem(element, "type")
          t[:type] = type.text
        end

        if discharge_date = elem(element, "dischargeDate")
          t[:discharge_date] = Date.parse(discharge_date.text)
        end

        return t
      end

      # Process a "homeHealthEpisodeDates" element
      def process_home_health_episode_dates(element)
        h = {}

        if start_date = elem(element, "homeHealthEpisodeStartDate")
          h[:start_date] = Date.parse(start_date.text)
        end

        if end_date = elem(element, "homeHealthEpisodeEndDate")
          h[:end_date] = Date.parse(end_date.text)
        end

        if earliest_bill_accepted_date = elem(element, "homeHealthEarliestBillAcceptedDate")
          h[:earliest_bill_accepted_date] = Date.parse(earliest_bill_accepted_date.text)
        end

        if latest_bill_accepted_date = elem(element, "homeHealthLatestBillAcceptedDate")
          h[:latest_bill_accepted_date] = Date.parse(latest_bill_accepted_date.text)
        end

        return h
      end

      # Process a "period" element
      def process_period(element)
        p = {}

        if year = elem(element, "year")
          p[:year] = year.text.to_i
        end

        if total_sessions = elem(element, "totalSessions")
          p[:total_sessions] = total_sessions.text.to_i
        end

        return p
      end

      # Process a "session" element
      def process_session(element)
        s = {}

        if hcpcs = elem(element, "hcpcs")
          s[:hcpcs] = hcpcs.text
        end

        if from = elem(element, "from")
          s[:from] = Date.parse(from.text)
        end

        if thru = elem(element, "thru")
          s[:thru] = Date.parse(thru.text)
        end

        if period = elem(element, "period")
          s[:period] = period.text.to_i
        end

        if quantity = elem(element, "quantity")
          s[:quantity] = quantity.text.to_i
        end

        if type = elem(element, "type")
          s[:type] = type.text
        end

        return s
      end

      # Process a "mspData" element
      def process_msp(element)
        m = {}

        if effective_date = elem(element, "effectiveDate")
          m[:effective_date] = Date.parse(effective_date.text)
        end

        if termination_date = elem(element, "terminationDate")
          m[:termination_date] = Date.parse(termination_date.text)
        end

        if code = elem(element, "mspCode")
          m[:code] = code.text
        end

        if subscriber_name = elem(element, "subscriberName")
          m[:subscriber_name] = subscriber_name.text
        end

        if policy_number = elem(element, "policyNumber")
          m[:policy_number] = policy_number.text
        end

        if patient_relationship = elem(element, "patientRelationship")
          m[:patient_relationship] = patient_relationship.text
        end

        if remarks_codes = elem(element, "remarksCodes")
          m[:remarks_codes] = remarks_codes.text
        end

        insurer_name = elem(element, "insurerName")
        insurer_address_1 = elem(element, "insurerAddress1")
        insurer_address_2 = elem(element, "insurerAddress2")
        insurer_city = elem(element, "insurerCity")
        insurer_state = elem(element, "insurerState")
        insurer_zip_code = elem(element, "insurerZipCode")
        
        if insurer_name ||
           insurer_address_1 ||
           insurer_address2 || 
           insurer_city ||
           insurer_state ||
           insurer_zip_code

           m[:insurer] = {}
           m[:insurer][:name] = insurer_name.text if insurer_name
           m[:insurer][:address_1] = insurer_address_1.text if insurer_address_1
           m[:insurer][:address_2] = insurer_address_2.text if insurer_address_2
           m[:insurer][:city] = insurer_city.text if insurer_city
           m[:insurer][:state] = insurer_state.text if insurer_state
           m[:insurer][:zip_code] = insurer_zip_code.text if insurer_zip_code
        end

        group_name = elem(element, "groupName")
        group_number = elem(element, "groupNumber")

        if group_name || group_number
          m[:group] = {}
          m[:group][:name] = group_name.text if group_name
          m[:group][:number] = group_number.text if group_number
        end

        return m
      end

      # Process a "homeHealthCertification" element
      def process_home_health_certification(element)
        h = {}

        if hcpcs = elem(element, "hcpcs")
          h[:hcpcs] = hcpcs.text
        end

        if from_date = elem(element, "fromDate")
          h[:from_date] = Date.parse(from_date.text)
        end

        return h
      end

    end
  end
end
