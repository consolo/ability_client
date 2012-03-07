# Class for submitting a Claim Inquiry
class Ability::Client::ClaimInquiry

  CLAIMS_ENDPOINT = "https://www.abilitynetwork.com/portal/seapi/services/DDEClaimInquiry"

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

  def initialize(client, service_id, opts)
    @client = client
    @service_id = service_id
    @opts = opts
  end

  def submit
    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct! :xml
    xml.claimInquiryRequest(:xmlns => "http://www.visionshareinc.com/seapi/2008-09-22") {
      xml.medicareMainframe {
        xml.application {
          xml.facilityState @opts[:facility_state]
          xml.lineOfBusiness @opts[:line_of_business]
        }
        xml.credential {
          xml.userId @client.user
          xml.password @client.password
        }
      }
      if @opts[:beneficiary]
        xml.details {
          xml.detail "Beneficiary"
        }
      end
      xml.searchCriteria(:maxResults => @opts[:max_results] || 100) {
        xml.npi @opts[:npi]
        xml.hic @opts[:hic]
        xml.status CLAIM_STATUSES[@opts[:status]]
        xml.location @opts[:location]
        xml.typeOfBill @opts[:bill_type]
        xml.fromDate @opts[:from_date]
        xml.toDate @opts[:to_date]
        xml.totalCharges @opts[:total_charges].to_s
      }
    }

    doc = @client.parse_xml(@client.post("#{CLAIMS_ENDPOINT}/#{@service_id}", xml.target!))
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

      if @opts[:beneficiary]
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
end
