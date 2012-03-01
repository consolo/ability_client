require "rest-client"
require "builder"
require "rexml/document"

require File.expand_path(File.join(File.dirname(__FILE__), "version"))

# Class for interacting with the ABILITY ACCESS API.
class Ability::Client

  CLAIM_STATUSES = {
    :good => "A",
    :inactive => "I",
    :suspense => "S",
    :manual_move => "M",
    :paid_partial_pay => "P",
    :reject => "R",
    :deny => "D",
    :rtp => "T",
    :ret_to_pro => "U"
  }

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
    services_endpoint = "https://portal.abilitynetwork.com/portal/services"
    doc = parse_xml(get(services_endpoint))
    doc.elements.to_a("//services/service").map do |e|
      {
        :id => e.attributes["id"].to_i,
        :type => e.attributes["type"],
        :name => e.elements.to_a("name").first.text,
        :uri => e.elements.to_a("uri").first.text
      }
    end
  end

  # Returns the results of a claim inquiry search
  def claim_inquiry(service_id, *args)
    opts = args_to_hash(*args)

    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct! :xml
    xml.claimInquiryRequest(:xmlns => "http://www.visionshareinc.com/seapi/2008-09-22") {
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
      if opts[:beneficiary]
        xml.details {
          xml.detail "Beneficiary"
        }
      end
      xml.searchCriteria(:maxResults => opts[:max_results] || 100) {
        xml.npi opts[:npi]
        xml.hic opts[:hic]
        xml.status CLAIM_STATUSES[opts[:status]]
        xml.location opts[:location]
        xml.typeOfBill opts[:bill_type]
        xml.fromDate opts[:from_date]
        xml.toDate opts[:to_date]
        xml.totalCharges opts[:total_charges].to_s
      }
    }

    claims_endpoint = "https://www.abilitynetwork.com/portal/seapi/services/DDEClaimInquiry/#{service_id}"
    doc = parse_xml(post(claims_endpoint, xml.target!))
    doc.elements.to_a("//claimInquiryResponse/searchResult/claim").map do |e|
      claim = {}
      claim[:npi] = e.elements.to_a("npi").first.text
      claim[:hic] = e.elements.to_a("hic").first.text 
      claim[:medicare_provider_number] = e.elements.to_a("medicareProviderNumber").first.text 

      raw_status = e.elements.to_a("status").first.text
      claim_status = CLAIM_STATUSES.select{ |k,v| v == raw_status }.first[0]
      claim[:status] = claim_status

      claim[:location] = e.elements.to_a("location").first.text
      claim[:bill_type] = e.elements.to_a("typeOfBill").first.text
      claim[:from_date] = Date.parse(e.elements.to_a("fromDate").first.text)
      claim[:to_date] = Date.parse(e.elements.to_a("toDate").first.text)
      claim[:admission_date] = Date.parse(e.elements.to_a("admissionDate").first.text)
      claim[:received_date] = Date.parse(e.elements.to_a("receivedDate").first.text)
      claim[:last_name] = e.elements.to_a("lastName").first.text
      claim[:first_initial] = e.elements.to_a("firstInitial").first.text
      claim[:total_charges] = e.elements.to_a("totalCharges").first.text.to_f
      claim[:provider_reimbursement] = e.elements.to_a("providerReimbursement").first.text.to_f
      claim[:processed_date] = Date.parse(e.elements.to_a("processedDate").first.text)
      claim[:payment_cancelled_date] = Date.parse(e.elements.to_a("paymentCancelledDate").first.text)
      claim[:reason_codes] = e.elements.to_a("reasonCodes/reasonCode").map { |r| r.text }
      claim[:non_payment_code] = e.elements.to_a("nonPaymentCode").first.text

      if opts[:beneficiary]
        claim[:beneficiary] = {
          :patient_control_number => e.elements.to_a("patientControlNumber").first.text,
          :first_name => e.elements.to_a("firstName").first.text,
          :middle_initial => e.elements.to_a("middleInitial").first.text,
          :date_of_birth => Date.parse(e.elements.to_a("dateOfBirth").first.text),
          :sex => e.elements.to_a("sex").first.text,
          :address_1 => e.elements.to_a("address1").first.text,
          :address_2 => e.elements.to_a("address2").first.text,
          :address_3 => e.elements.to_a("address3").first.text,
          :zip_code => e.elements.to_a("zipCode").first.text
        }
      end

      claim
    end
  end

  # Return the results of an eligibility inquiry
  def eligibility_inquiry(service_id, *args)
    opts = args_to_hash(*args)

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
        xml.detail "FissEligibility" if opts[:fiss_eligibility]
        xml.detail "PreventativeServices" if opts[:preventative_services]
        xml.detail "CwfEligibility" if opts[:cwf_eligibility]
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

    eligibility_endpoint = "https://access.abilitynetwork.com/portal/seapi/services/DDEEligibilityInquiry/#{service_id}"
    doc = parse_xml(post(eligibility_endpoint, xml.target!))
    doc.elements.to_a("//eligibilityInquiryResponse/eligibility").inject({}) { |eligibility, e|

      if opts[:fiss_eligibility]
        eligibility[:fiss_eligibility] = e.elements.to_a("fissEligibility").inject({}) { |fiss, f|

          fiss[:beneficiary] = f.elements.to_a("beneficiary").map { |b|
            {
              :hic => b.elements.to_a("hic").first.text,
              :last_name => b.elements.to_a("lastName").first.text,
              :first_name => b.elements.to_a("firstName").first.text,
              :middle_initial => b.elements.to_a("middleInitial").first.text,
              :sex => b.elements.to_a("sex").first.text,
              :date_of_birth => Date.parse(b.elements.to_a("dateOfBirth").first.text),
              :date_of_death => Date.parse(b.elements.to_a("dateOfDeath").first.text),
              :address_1 => b.elements.to_a("address1").first.text,
              :address_2 => b.elements.to_a("address2").first.text,
              :address_3 => b.elements.to_a("address3").first.text,
              :zip_code => b.elements.to_a("zipCode").first.text
            }
          }.first

          fiss[:current_entitlement] = f.elements.to_a("currentEntitlement").map { |c|
            {
              :part_a => {
                :effective_date => Date.parse(c.elements.to_a("partAEffectiveDate").first.text),
                :termination_date => Date.parse(c.elements.to_a("partATerminationDate").first.text)
              },
              :part_b => {
                :effective_date => Date.parse(c.elements.to_a("partBEffectiveDate").first.text),
                :termination_date => Date.parse(c.elements.to_a("partBTerminationDate").first.text)
              }
            }
          }.first

          fiss[:current_benefit_period] = f.elements.to_a("currentBenefitPeriodData").map { |c|
            {
              :first_bill_date => Date.parse(c.elements.to_a("firstBillDate").first.text),
              :last_bill_date => Date.parse(c.elements.to_a("lastBillDate").first.text),
              :hospital_full_days => c.elements.to_a("hospitalFullDays").first.text.to_i,
              :hospital_part_days => c.elements.to_a("hospitalPartDays").first.text.to_i,
              :snf_full_days => c.elements.to_a("snfFullDays").first.text.to_i,
              :snf_part_days => c.elements.to_a("snfPartDays").first.text.to_i,
              :remaining_inpatient_deductible => c.elements.to_a("inpatientDeductibleRemaining").first.text.to_f,
              :remaining_blood_pints => c.elements.to_a("bloodPintsRemaining").first.text.to_i
            }
          }.first

          fiss[:psychiatric] = f.elements.to_a("psychiatric").map { |p|
            {
              :remaining_days => p.elements.to_a("daysRemaining").first.text.to_i,
              :pre_entitlement_days_used => p.elements.to_a("preEntitlementDaysUsed").first.text.to_i,
              :discharge_date => Date.parse(p.elements.to_a("dischargeDate").first.text),
              :interim_date_indicator => p.elements.to_a("interimDateIndicator").first.text
            }
          }.first

          fiss[:reason_codes] = f.elements.to_a("reasonCodes/reasonCode").map { |rc| rc.text }

          # Result for inject
          fiss
        }
      end

      if opts[:preventative_services]
        eligibility[:preventative_services] = e.elements.to_a("preventativeServices/preventativeService").map { |p|
          {
            :category => p.elements.to_a("category").first.text,
            :hcpcs => p.elements.to_a("hcpcs").first.text,
            :technical_date => p.elements.to_a("technicalDate").first.text,
            :professional_date => p.elements.to_a("professionalDate").first.text
          }

        }
      end

      if opts[:cwf_eligibility]
        eligibility[:cwf_eligibility] = e.elements.to_a("cwfEligibility").inject({}) { |cwf, c|

          cwf[:current_entitlement] = c.elements.to_a("currentEntitlement").map { |ce|
            {
              :part_a => {
                :effective_date => Date.parse(ce.elements.to_a("partAEffectiveDate").first.text),
                :termination_date => Date.parse(ce.elements.to_a("partATerminationDate").first.text)
              },
              :part_b => {
                :effective_date => Date.parse(ce.elements.to_a("partBEffectiveDate").first.text),
                :termination_date => Date.parse(ce.elements.to_a("partBTerminationDate").first.text)
              }
            }
          }.first

          cwf[:prior_entitlement] = c.elements.to_a("priorEntitlement").map { |pe|
            { 
              :part_a => {
                :effective_date => Date.parse(pe.elements.to_a("partAEffectiveDate").first.text),
                :termination_date => Date.parse(pe.elements.to_a("partATerminationDate").first.text)
              },
              :part_b => {
                :effective_date => Date.parse(pe.elements.to_a("partAEffectiveDate").first.text),
                :termination_date => Date.parse(pe.elements.to_a("partATerminationDate").first.text)
              }
            }
          }.first

          cwf[:lifetime] = c.elements.to_a("lifetimeData").map { |l|
            {
              :remaining_reserve_days => l.elements.to_a("reserveDaysRemaining").first.text.to_i,
              :psychiatric_days_available => l.elements.to_a("psychiatricDaysAvailable").first.text.to_i
            }
          }.first
              
          cwf[:current_benefit_period] = c.elements.to_a("currentBenefitPeriodData").map { |bp|
            {
              :first_bill_date => Date.parse(bp.elements.to_a("firstBillDate").first.text),
              :last_bill_date => Date.parse(bp.elements.to_a("lastBillDate").first.text),
              :hospital_full_days => bp.elements.to_a("hospitalFullDays").first.text.to_i,
              :hospital_part_days => bp.elements.to_a("hospitalPartDays").first.text.to_i,
              :snf_full_days => bp.elements.to_a("snfFullDays").first.text.to_i,
              :snf_part_days => bp.elements.to_a("snfPartDays").first.text.to_i,
              :remaining_inpatient_deductible => bp.elements.to_a("inpatientDeductibleRemaining").first.text.to_f,
              :remaining_blood_pints => bp.elements.to_a("bloodPintsRemaining").first.text.to_i
            }
          }.first

          cwf[:prior_benefit_period] = c.elements.to_a("priorBenefitPeriodData").map { |bp|
            {
              :first_bill_date => Date.parse(bp.elements.to_a("firstBillDate").first.text),
              :last_bill_date => Date.parse(bp.elements.to_a("lastBillDate").first.text),
              :hospital_full_days => bp.elements.to_a("hospitalFullDays").first.text.to_i,
              :hospital_part_days => bp.elements.to_a("hospitalPartDays").first.text.to_i,
              :snf_full_days => bp.elements.to_a("snfFullDays").first.text.to_i,
              :snf_part_days => bp.elements.to_a("snfPartDays").first.text.to_i,
              :remaining_inpatient_deductible => bp.elements.to_a("inpatientDeductibleRemaining").first.text.to_f,
              :remaining_blood_pints => bp.elements.to_a("bloodPintsRemaining").first.text.to_i
            }
          }.first

          cwf[:current_part_b] = c.elements.to_a("currentPartBData").map { |pb|
            {
              :service_year => pb.elements.to_a("serviceYear").first.text,
              :remaining_blood_pints => pb.elements.to_a("bloodPintsRemaining").first.text.to_i,
              :remaining_psychiatric => pb.elements.to_a("psychiatricRemaining").first.text.to_f,
              :remaining_physical_therapy => pb.elements.to_a("physicalTherapyRemaining").first.text.to_f,
              :remaining_occupational_therapy => pb.elements.to_a("occupationalTherapyRemaining").first.text.to_f
            }
          }.first

          cwf[:prior_part_b] = c.elements.to_a("priorPartBData").map { |pb|
            {
              :service_year => pb.elements.to_a("serviceYear").first.text,
              :remaining_blood_pints => pb.elements.to_a("bloodPintsRemaining").first.text.to_i,
              :remaining_psychiatric => pb.elements.to_a("psychiatricRemaining").first.text.to_f,
              :remaining_physical_therapy => pb.elements.to_a("physicalTherapyRemaining").first.text.to_f,
              :remaining_occupational_therapy => pb.elements.to_a("occupationalTherapyRemaining").first.text.to_f
            }
          }.first

          # Result for inject
          cwf
        }
      end
        
      # Result for inject
      eligibility
    }
  end


  # Return the results of a claim status inquiry
  def claim_status_inquiry(service_id, *args)
    opts = args_to_hash(*args)

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

    claim_status_endpoint = "https://access.abilitynetwork.com/portal/seapi/services/PPTNClaimStatusInquiry/#{service_id}"
    doc = parse_xml(post(claim_status_endpoint, xml.target!))
    doc.elements.to_a("//claimStatusInquiryResponse").inject({}) { |hsh, e|

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

  # Generate a password
  def generate_password(service_id)
    generate_password_endpoint = "https://access.abilitynetwork.com/portal/seapi/services/PasswordGenerate/#{service_id}"
    post(generate_password_endpoint)
  end

  # Change a password or clerk password
  def change_password(service_id, new_password, *args)
    opts = args_to_hash(*args)

    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct! :xml, :standalone => "yes"
    xml.passwordChangeRequest(:xmlns => "http://www.visionshareinc.com/seapi/2008-09-22") {
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
      xml.newPassword new_password
    }

    change_password_endpoint = "https://access.abilitynetwork.com/portal/seapi/services/PasswordChange/#{service_id}"
    doc = parse_xml(post(change_password_endpoint, xml.target!))
    
    if doc.elements.to_a("passwordChangeResponse").first
      # Change client password unless clerk password is being changed
      self.password = new_password unless opts[:clerk]
    end
  end


  private

  def args_to_hash(*args)
    Hash[*args.flatten]
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


end
