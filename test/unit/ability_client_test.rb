require File.expand_path(File.join(File.dirname(__FILE__), "..", "test_helper"))
require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "ability"))

class AbilityClientTest < Test::Unit::TestCase

  def setup
    @client = Ability::Client.new(:user => "DS77915", :password => "somepass")
    @service_id = "80"
  end

  def test_services

    services_endpoint = "https://portal.abilitynetwork.com/portal/services"

    stub_request(:get, services_endpoint).to_return(:body => load_xml("service_list_response"))

    assert_equal [
      { :id => 1,
        :type => "BatchSubmit",
        :name => "NGS Medicare Part B Submit Claims (Downstate NY)",
        :uri => "https://portal.visionshareinc.com/portal/seapi/services/BatchSubmit/1" },
      { :id => 2,
        :type => "BatchReceiveList",
        :name => "NGS Medicare Part B Receive Reports / Remits (Downstate NY)",
        :uri => "https://portal.visionshareinc.com/portal/seapi/services/BatchReceiveList/2" },
      { :id => 79,
        :type => "BatchSubmit",
        :name => "NGS Medicare Part B Submit Claims (CT)",
        :uri => "https://portal.visionshareinc.com/portal/seapi/services/BatchSubmit/79" },
      { :id => 80,
        :type => "BatchReceiveList",
        :name => "NGS Medicare Part B Receive Reports / Remits (CT)",
        :uri => "https://portal.visionshareinc.com/portal/seapi/services/BatchReceiveList/80" }
    ], @client.services
  end

  def test_claim_inquiry
    claim_endpoint = "https://www.abilitynetwork.com/portal/seapi/services/DDEClaimInquiry/#{@service_id}"
    stub_request(:post, claim_endpoint).with(:body => load_xml("claim_inquiry_request")).to_return(:body => load_xml("claim_inquiry_response"))

    assert_equal([
      { :npi => "123457890",
        :hic => "123456789A",
        :medicare_provider_number => "123456",
        :status => :paid_partial_pay,
        :location => "B9997",
        :bill_type => "131",
        :from_date => Date.parse("2007-05-08"),
        :to_date => Date.parse("2007-05-08"),
        :admission_date => Date.parse("2007-05-08"),
        :received_date => Date.parse("2007-05-15"),
        :last_name => "Doe",
        :first_initial => "J",
        :total_charges => 100.23,
        :provider_reimbursement => 50.23,
        :processed_date => Date.parse("2007-06-04"),
        :payment_cancelled_date => Date.parse("2007-06-14"),
        :reason_codes => [ "37192" ],
        :non_payment_code => "123",
        :beneficiary => {
          :patient_control_number => "PCN123456789",
          :first_name => "John",
          :middle_initial => "Z",
          :date_of_birth => Date.parse("1942-01-07"),
          :sex => "M",
          :address_1 => "123 street",
          :address_2 => "city",
          :address_3 => "state",
          :zip_code => "987654321"
        }
      }
    ], @client.claim_inquiry(@service_id,
      :beneficiary => true,
      :facility_state => 'OH',
      :line_of_business => 'PartA',
      :npi => "1234567893",
      :hic => "123456789A",
      :status => :paid_partial_pay,
      :location => "B9997",
      :bill_type => "131",
      :from_date => Date.parse("2007-05-08"),
      :to_date => Date.parse("2007-05-08"),
      :total_charges => 100.23
    ))
  end

  def test_eligibility_inquiry
    eligibility_endpoint = "https://access.abilitynetwork.com/portal/seapi/services/DDEEligibilityInquiry/#{@service_id}"
    stub_request(:post, eligibility_endpoint).with(:body => load_xml("eligibility_inquiry_request")).to_return(:body => load_xml("eligibility_inquiry_response"))

    assert_equal({
      :fiss_eligibility => {
        :beneficiary => {
          :hic => "1234567890A",
          :last_name => "Doe",
          :first_name => "John",
          :middle_initial => "Z",
          :sex => "M",
          :date_of_birth => Date.parse("1942-01-07"),
          :date_of_death => Date.parse("2010-01-07"),
          :address_1 => "123 street",
          :address_2 => "city",
          :address_3 => "state",
          :zip_code => "987654321"
        },
        :current_entitlement => {
          :part_a => {
            :effective_date => Date.parse("2004-06-15"),
            :termination_date => Date.parse("2004-06-15")
          },
          :part_b => {
            :effective_date => Date.parse("2004-06-15"),
            :termination_date => Date.parse("2004-06-15")
          }
        },
        :current_benefit_period => {
          :first_bill_date => Date.parse("2004-06-15"),
          :last_bill_date => Date.parse("2004-06-15"),
          :hospital_full_days => 75,
          :hospital_part_days => 43,
          :snf_full_days => 25,
          :snf_part_days => 15,
          :remaining_inpatient_deductible => 1555.75,
          :remaining_blood_pints => 3
        },
        :psychiatric => {
          :remaining_days => 190,
          :pre_entitlement_days_used => 21,
          :discharge_date => Date.parse("2004-06-15"),
          :interim_date_indicator => "Y"
        },
        :reason_codes => ["U1231","21349"]
      },
      :preventative_services => [
        {
          :category => "CARD",
          :hcpcs => "939023",
          :technical_date => "03042010",
          :professional_date => "04042010"
        },
        {
          :category => "IPPE",
          :hcpcs => "G0368",
          :technical_date => "0000",
          :professional_date => "SRV"
        }
      ],
      :cwf_eligibility => {
        :current_entitlement => {
          :part_a => {
            :effective_date => Date.parse("2004-06-15"),
            :termination_date => Date.parse("2004-06-15")
          },
          :part_b => {
            :effective_date => Date.parse("2004-06-15"),
            :termination_date => Date.parse("2004-06-15")
          }
        },
        :prior_entitlement => {
          :part_a => {
            :effective_date => Date.parse("2000-06-15"),
            :termination_date => Date.parse("2000-06-15")
          },
          :part_b => {
            :effective_date => Date.parse("2000-06-15"),
            :termination_date => Date.parse("2000-06-15")
          }
        },
        :lifetime => {
          :remaining_reserve_days => 60,
          :psychiatric_days_available => 190
        },
        :current_benefit_period => {
          :first_bill_date => Date.parse("2004-06-15"),
          :last_bill_date => Date.parse("2004-06-15"),
          :hospital_full_days => 75,
          :hospital_part_days => 43,
          :snf_full_days => 25,
          :snf_part_days => 15,
          :remaining_inpatient_deductible => 1555.75,
          :remaining_blood_pints => 3
        },
        :prior_benefit_period => {
          :first_bill_date => Date.parse("2000-06-15"),
          :last_bill_date => Date.parse("2000-06-15"),
          :hospital_full_days => 95,
          :hospital_part_days => 63,
          :snf_full_days => 45,
          :snf_part_days => 35,
          :remaining_inpatient_deductible => 3555.75,
          :remaining_blood_pints => 5
        },
        :current_part_b => {
          :service_year => "10",
          :remaining_blood_pints => 7,
          :remaining_psychiatric => 111.11,
          :remaining_physical_therapy => 211.11,
          :remaining_occupational_therapy => 311.11
        },
        :prior_part_b => {
          :service_year => "09",
          :remaining_blood_pints => 9,
          :remaining_psychiatric => 411.11,
          :remaining_physical_therapy => 511.11,
          :remaining_occupational_therapy => 611.11
        }
      }
    }, @client.eligibility_inquiry(@service_id,
      :facility_state => "OH",
      :line_of_business => "PartA",
      :fiss_eligibility => true,
      :preventative_services => true,
      :cwf_eligibility => true,
      :beneficiary => {
        :hic => "123456789A",
        :last_name => "Doe",
        :first_name => "John",
        :sex => "M",
        :date_of_birth => Date.parse("1925-05-08")
      }
    ))
  end

  def test_claim_status_inquiry
    claim_status_endpoint = "https://access.abilitynetwork.com/portal/seapi/services/PPTNClaimStatusInquiry/#{@service_id}"
    stub_request(:post, claim_status_endpoint).with(:body => load_xml("claim_status_inquiry_request")).to_return(:body => load_xml("claim_status_inquiry_response"))

    assert_equal({
      :beneficiary => {
        :npi => "1234567890",
        :hic => "1234567890A",
        :last_name => "Last",
        :first_name => "First",
        :middle_initial => "I",
        :sex => "F",
        :date_of_birth => Date.parse("2000-01-01"),
        :trace_number => "01112012010492"
      },
      :claims => [
        {
          :icn => "123456789ABCD",
          :category_code_1 => "F3F",
          :status_code_1 => "1",
          :category_code_2 => "F3",
          :status_code_2 => "101",
          :total_billed => 1500.25,
          :paid_date => Date.parse("2001-03-01"),
          :total_paid => 50.5,
          :check_number => "12345678",
          :check_date => Date.parse("2001-04-01"),
          :payment_method => "EFT",
          :service_lines => [
            {
              :from_date => Date.parse("2001-02-01"),
              :to_date => Date.parse("2001-02-02"),
              :hcpcs => "G1234",
              :modifier_1 => 59,
              :modifier_2 => 60,
              :modifier_3 => 61,
              :modifier_4 => 62,
              :units_of_service => 999,
              :category_code => "F1",
              :status_code => "65",
              :billed_amount => 75.75,
              :paid_amount => 25.25,
              :control_number => "0123456789"
            }
          ]
        }
      ]
    }, @client.claim_status_inquiry(@service_id,
      :facility_state => "OK",
      :line_of_business => "PartB",
      :clerk => {
        :user => "ABCD",
        :password => "clerkpass"
      },
      :npi => "123456789",
      :hic => "123456789A",
      :from_date => Date.parse("2000-01-01"),
      :to_date => Date.parse("2020-01-01"),
      :hcpcs => "A1234",
      :icn => "1234567890123"
    ))
    
  end

  def test_generate_password
    generate_password_endpoint = "https://access.abilitynetwork.com/portal/seapi/services/PasswordGenerate/#{@service_id}"
    stub_request(:post, generate_password_endpoint).to_return(:body => "xI5$r2cl")
    assert_equal "xI5$r2cl", @client.generate_password(@service_id)
  end

  def test_change_password
    change_password_endpoint = "https://access.abilitynetwork.com/portal/seapi/services/PasswordChange/#{@service_id}"
    stub_request(:post, change_password_endpoint).with(:body => load_xml("password_change_request")).to_return(:body => load_xml("password_change_response"))

    new_password = "NewPwd01"

    @client.change_password(@service_id, new_password, :facility_state => 'OK', :line_of_business => 'PartB')
    assert_equal(new_password, @client.password)
  end

  private

  def load_xml(name)
    xml_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "#{name}.xml"))
    File.read(File.new(xml_path))
  end

end
