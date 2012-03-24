require File.expand_path(File.join(File.dirname(__FILE__), "..", "test_helper"))
require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "ability"))

class AbilityClientTest < Test::Unit::TestCase

  def setup
    @client = Ability::Client
    @client.configure({
      :user => "DS77915",
      :password => "somepass",
      :service_id => 80,
    })
  end

  def test_services
    stub_request(:get, @client::API_ROOT).to_return(:body => response_xml(:service_list))
    services = @client.services
    assert_equal "1", services[0]["id"]
    assert_equal "NGS Medicare Part B Submit Claims (Downstate NY)", services[0]["name"]
  end

  def test_eligibility_inquiry
    eligibility_endpoint = @client.send(:endpoint, "DDEEligibilityInquiry")
    stub_request(:post, eligibility_endpoint).with(:body => request_xml(:eligibility_inquiry)).to_return(:body => response_xml(:eligibility_inquiry))
    eligibility = @client.eligibility_inquiry(
      :facility_state => "OH",
      :line_of_business => "PartA",
      :details => [ :all ],
      :beneficiary => {
        :hic => "123456789A",
        :last_name => "Doe",
        :first_name => "John",
        :sex => "M",
        :date_of_birth => Date.parse("1925-05-08")
      }
    )
    assert_equal "1234567890A", eligibility["screen1751"]["beneficiary"]["hic"]
  end

  def test_generate_password
    generate_password_endpoint = @client.send(:endpoint, "PasswordGenerate")
    stub_request(:post, generate_password_endpoint).to_return(:body => "xI5$r2cl")
    assert_equal "xI5$r2cl", @client.generate_password
  end

  def test_change_password
    change_password_endpoint = @client.send(:endpoint, "PasswordChange")
    stub_request(:post, change_password_endpoint).with(:body => request_xml(:password_change)).to_return(:body => response_xml(:password_change))
    new_password = "NewPwd01"
    @client.change_password(new_password, :facility_state => "OK", :line_of_business => "PartA")
    assert_equal new_password, @client.password
  end

  def raises_errors
    change_password_endpoint = @client.send(:endpoint, "PasswordChange")
    @client.password = "somepass"
    stub_request(:post, change_password_endpoint).with(:body => request_xml(:password_change)).to_return(:status => 400, :body => error_xml(:password_expired))

    assert_raises(Ability::ResponseError) do
      @client.change_password("NewPwd01", :facility_state => "OK", :line_of_business => "PartA")
    end
  end

  def test_headers
    change_password_endpoint = @client.send(:endpoint, "PasswordChange")
    @client.password = "somepass"
    stub_request(:post, change_password_endpoint).with(:body => request_xml(:password_change)).to_return(:body => response_xml(:password_change))
    @client.change_password("NewPwd01", :facility_state => "OK", :line_of_business => "PartA")

    assert_requested :post, change_password_endpoint,
      :headers => {
        "X-SEAPI-Version" => "1",
        "User-Agent" => "Ruby Ability Client/#{Ability::Client.version}"
      }
  end

end
