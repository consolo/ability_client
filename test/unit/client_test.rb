require File.expand_path(File.join(File.dirname(__FILE__), "..", "test_helper"))
require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "ability"))

class AbilityClientTest < Test::Unit::TestCase

  def setup
    @client = Ability::Client.new("DS77915", "somepass")
    @service_id = "80"
  end

  def test_services

    services_endpoint = "https://portal.abilitynetwork.com/portal/services"

    stub_request(:get, services_endpoint).to_return(:body => response_xml(:service_list))

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
    stub_request(:post, claim_endpoint).with(:body => request_xml(:claim_inquiry)).to_return(:body => response_xml(:claim_inquiry))

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

  def test_eligibility_inquiry_fss0_1751
    stub_eligibility_request(:fss0_1751)

    assert_equal({
      :screen_1751 => {
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
      }
    }, eligibility_inquiry(:fss0_1751))
  end

  def test_eligibility_inquiry_fss0_1752

    stub_eligibility_request(:fss0_1752)

    assert_equal({:screen_1752 => {
      :part_b => {
        :service_year => "09",
        :medical_expense => 200.00,
        :remaining_blood_pints => 3,
        :psychiatric_expense => 200.00,
      },
      :mco_plans => [
        {
          :type => "sometype",
          :code => "34321",
          :option_code => "32",
          :effective_date => Date.parse("2004-06-15"),
          :termination_date => Date.parse("2012-03-01"),
        }
      ],
      :hospice => {
        :period => 1,
        :first_provider_start_date => Date.parse("2004-06-15"),
        :first_provider_id => "3203941",
        :first_intermediary_id => "A4352",
        :first_owner_change_start_date => Date.parse("2004-06-15"),
        :first_owner_change_provider_id => "3234213",
        :first_owner_change_intermediary_id => "321341",
        :second_provider_start_date => Date.parse("2004-06-15"),
        :second_provider_id => "3113323",
        :second_intermediary_id => "230392",
        :second_owner_change_start_date => Date.parse("2004-06-15"),
        :second_owner_change_provider_id => "239092",
        :second_owner_change_intermediary_id => "30293",
        :termination_date => Date.parse("2012-03-01"),
        :first_billed_date => Date.parse("2004-06-15"),
        :last_billed_date => Date.parse("2012-03-01"),
        :days_billed => 20,
        :revocation_indicator => 2
      }
    }}, eligibility_inquiry(:fss0_1752))
  end

  def test_eligibility_inquiry_fss0_175J 
    stub_eligibility_request(:fss0_175J)

    assert_equal({:screen_175J => {
      :preventative_services => [
        {
          :category => "CARD",
          :hcpcs => "G1234",
          :technical_date => "0000",
          :professional_date => "SRV"
        }
      ]
    }}, eligibility_inquiry(:fss0_175J))
  end

  def test_eligibility_inquiry_fss0_1755
    stub_eligibility_request(:fss0_1755)

    assert_equal({:screen_1755 => {
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
    }}, eligibility_inquiry(:fss0_1755))
  end

  def test_eligibility_inquiry_fss0_1756
    stub_eligibility_request(:fss0_1756)

    assert_equal({:screen_1756 => {
      :data_indicator => "Y",
      :plan_enrollment_code => 10,
      :current_mco_plan => {
        :type => "TYPE1",
        :code => "30",
        :option_code => "20",
        :effective_date => Date.parse("2000-06-03"),
        :termination_date => Date.parse("2012-02-01")
      },
      :prior_mco_plan => {
        :type => "TYPE1",
        :code => "30",
        :option_code => "20",
        :effective_date => Date.parse("2000-06-03"),
        :termination_date => Date.parse("2012-02-01")
      },
      :other_entitlement_code => "XCS22",
      :other_entitlement_date => Date.parse("2000-06-15"),
      :esrd_code => 20,
      :esrd_date => Date.parse("2000-06-15"),
      :psychiatric => {
        :remaining_days => 190,
        :pre_entitlement_days_used => 21,
        :discharge_date => Date.parse("2004-06-15"),
        :interim_date_indicator => "Y"
      }
    }}, eligibility_inquiry(:fss0_1756))
  end

  def test_eligibility_inquiry_fss0_1757
    stub_eligibility_request(:fss0_1757)

    assert_equal({:screen_1757 => {
      :transplants => [
        {
          :covered => true,
          :type => "TT32",
          :discharge_date => Date.parse("2012-03-01")
        }
      ],
      :home_health_episode_dates =>  {
        :start_date => Date.parse("2012-03-01"),
        :end_date => Date.parse("2012-03-20"),
        :earliest_bill_accepted_date => Date.parse("2012-03-01"),
        :latest_bill_accepted_date => Date.parse("2012-03-20")
      }
    }}, eligibility_inquiry(:fss0_1757))
  end

  def test_eligibility_inquiry_fss0_1758_175C
    stub_eligibility_request(:fss0_1758_175C)

    assert_equal({:screen_1758_175C => {
      :period_1 => {
        :period => 1,
        :first_provider_start_date => Date.parse("2004-06-15"),
        :first_provider_id => "3203941",
        :first_intermediary_id => "A4352",
        :first_owner_change_start_date => Date.parse("2004-06-15"),
        :first_owner_change_provider_id => "3234213",
        :first_owner_change_intermediary_id => "321341",
        :second_provider_start_date => Date.parse("2004-06-15"),
        :second_provider_id => "3113323",
        :second_intermediary_id => "230392",
        :second_owner_change_start_date => Date.parse("2004-06-15"),
        :second_owner_change_provider_id => "239092",
        :second_owner_change_intermediary_id => "30293",
        :termination_date => Date.parse("2012-03-01"),
        :first_billed_date => Date.parse("2004-06-15"),
        :last_billed_date => Date.parse("2012-03-01"),
        :days_billed => 20,
        :revocation_indicator => 2
      },
      :period_2 => {
        :period => 2,
        :first_provider_start_date => Date.parse("2004-06-15"),
        :first_provider_id => "3203941",
        :first_intermediary_id => "A4352",
        :first_owner_change_start_date => Date.parse("2004-06-15"),
        :first_owner_change_provider_id => "3234213",
        :first_owner_change_intermediary_id => "321341",
        :second_provider_start_date => Date.parse("2004-06-15"),
        :second_provider_id => "3113323",
        :second_intermediary_id => "230392",
        :second_owner_change_start_date => Date.parse("2004-06-15"),
        :second_owner_change_provider_id => "239092",
        :second_owner_change_intermediary_id => "30293",
        :termination_date => Date.parse("2012-03-01"),
        :first_billed_date => Date.parse("2004-06-15"),
        :last_billed_date => Date.parse("2012-03-01"),
        :days_billed => 20,
        :revocation_indicator => 2
      },
      :period_3 => {
        :period => 3,
        :first_provider_start_date => Date.parse("2004-06-15"),
        :first_provider_id => "3203941",
        :first_intermediary_id => "A4352",
        :first_owner_change_start_date => Date.parse("2004-06-15"),
        :first_owner_change_provider_id => "3234213",
        :first_owner_change_intermediary_id => "321341",
        :second_provider_start_date => Date.parse("2004-06-15"),
        :second_provider_id => "3113323",
        :second_intermediary_id => "230392",
        :second_owner_change_start_date => Date.parse("2004-06-15"),
        :second_owner_change_provider_id => "239092",
        :second_owner_change_intermediary_id => "30293",
        :termination_date => Date.parse("2012-03-01"),
        :first_billed_date => Date.parse("2004-06-15"),
        :last_billed_date => Date.parse("2012-03-01"),
        :days_billed => 20,
        :revocation_indicator => 2
      },
      :period_4 => {
        :period => 4,
        :first_provider_start_date => Date.parse("2004-06-15"),
        :first_provider_id => "3203941",
        :first_intermediary_id => "A4352",
        :first_owner_change_start_date => Date.parse("2004-06-15"),
        :first_owner_change_provider_id => "3234213",
        :first_owner_change_intermediary_id => "321341",
        :second_provider_start_date => Date.parse("2004-06-15"),
        :second_provider_id => "3113323",
        :second_intermediary_id => "230392",
        :second_owner_change_start_date => Date.parse("2004-06-15"),
        :second_owner_change_provider_id => "239092",
        :second_owner_change_intermediary_id => "30293",
        :termination_date => Date.parse("2012-03-01"),
        :first_billed_date => Date.parse("2004-06-15"),
        :last_billed_date => Date.parse("2012-03-01"),
        :days_billed => 20,
        :revocation_indicator => 2
      }
    }}, eligibility_inquiry(:fss0_1758_175C))
  end

  def test_eligibility_inquiry_fss0_175K
    stub_eligibility_request(:fss0_175K)

    assert_equal({:screen_175K => {
      :counseling_periods => [
        {
          :year => 2012,
          :total_sessions => 4
        }
      ],
      :counseling_sessions => [
        {
          :hcpcs => "G1234",
          :from => Date.parse("2012-03-01"),
          :thru => Date.parse("2012-03-15"),
          :period => 2,
          :quantity => 1,
          :type => "T239"
        }
      ]
    }}, eligibility_inquiry(:fss0_175K))
  end

  def test_eligibility_inquiry_fss0_1759
    stub_eligibility_request(:fss0_1759)

    assert_equal({:screen_1759 => {
      :msps => [
        {
          :effective_date => Date.parse("2012-03-01"),
          :termination_date => Date.parse("2012-03-15"),
          :code => "C2039",
          :subscriber_name => "Subscriber",
          :policy_number => "XYZ123",
          :patient_relationship => "R1",
          :remarks_codes => "XX21",
          :insurer => {
            :name => "XYZ Insurance",
            :address_1 => "211 Test Street",
            :address_2 => "Suite 111",
            :city => "City",
            :state => "State",
            :zip_code => "40233"
          },
          :group => {
            :name => "GR321",
            :number => "G30291"
          }
        }
      ]
    }}, eligibility_inquiry(:fss0_1759))
  end

  def test_eligibility_inquiry_fss0_175L
    stub_eligibility_request(:fss0_175L)

    assert_equal({:screen_175L => {
      :home_health_certifications => [
        {
          :hcpcs => "G1234",
          :from_date => Date.parse("2012-03-01")
        }
      ]
    }}, eligibility_inquiry(:fss0_175L))
  end

  def test_claim_status_inquiry
    claim_status_endpoint = "https://access.abilitynetwork.com/portal/seapi/services/PPTNClaimStatusInquiry/#{@service_id}"
    stub_request(:post, claim_status_endpoint).with(:body => request_xml(:claim_status_inquiry)).to_return(:body => response_xml(:claim_status_inquiry))

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
    stub_request(:post, change_password_endpoint).with(:body => request_xml(:password_change)).to_return(:body => response_xml(:password_change))

    new_password = "NewPwd01"

    @client.change_password(@service_id, new_password, :facility_state => "OK", :line_of_business => "PartB")
    assert_equal(new_password, @client.password)
  end

  def raises_errors
    change_password_endpoint = "https://access.abilitynetwork.com/portal/seapi/services/PasswordChange/#{@service_id}"
    stub_request(:post, change_password_endpoint).with(:body => request_xml(:password_change)).to_return(:status => 400, :body => error_xml(:password_expired))

    assert_raises(Ability::ResponseError) do
      @client.change_password(@service_id, new_password, :facility_state => "OK", :line_of_business => "PartB")
    end
  end

  private

  # Stub an eligibility request
  def stub_eligibility_request(detail)
    eligibility_endpoint = "https://access.abilitynetwork.com/portal/seapi/services/DDEEligibilityInquiry/#{@service_id}"
    stub_request(:post, eligibility_endpoint).with(:body => request_xml(:eligibility_inquiry, detail)).to_return(:body => response_xml(:eligibility_inquiry, detail))
  end

  # Eligibility inquiry
  def eligibility_inquiry(detail)
    @client.eligibility_inquiry(@service_id, 
      :facility_state => "OH",
      :line_of_business => "PartA",
      :details => [ detail ],
      :beneficiary => {
        :hic => "123456789A",
        :last_name => "Doe",
        :first_name => "John",
        :sex => "M",
        :date_of_birth => Date.parse("1925-05-08")
      }
    )
  end

end
