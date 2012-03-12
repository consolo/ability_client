require File.expand_path(File.join(File.dirname(__FILE__), "..", "test_helper"))
require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "ability"))

class AbilityErrorTest < Test::Unit::TestCase
  
  def setup
    @message = "The Medicare application password has expired for the user ID. Reset the password using a terminal emulator or contact the MAC for assistance."
  end

  def test_error_class_is_automatically_generated
    Ability.send(:remove_const, :PasswordExpired) if Ability.const_defined?(:PasswordExpired)
    assert !Ability.const_defined?("PasswordExpired")
    error = Ability::Error.from_doc(xml(error_xml(:password_expired)))
    assert Ability.const_defined?("PasswordExpired")
  end

  def test_error_contains_attributes
    error = Ability::Error.from_doc(xml(error_xml(:password_expired)))
    assert_equal @message, error.message
    assert_equal "PasswordExpired", error.code
    assert_equal [{ :userId => "someuser" }, { :application => "???" }], error.details
  end

  def test_error_is_raisable_as_exception
    error = Ability::Error.from_doc(xml(error_xml(:password_expired)))
    assert_raises(Ability::PasswordExpired) do
      error.raise
    end
  end

  def test_message_is_passed_along_to_exception
    error = Ability::Error.from_doc(xml(error_xml(:password_expired)))
    error.raise
  rescue Ability::PasswordExpired => e
    assert_equal @message, e.message
  end

  def test_response_is_passed_along_to_exception
    response = Ability::Error::Response.new(xml(error_xml(:password_expired)))
    response.error.raise
  rescue Ability::ResponseError => e
    assert e.response
    assert_kind_of Ability::Error::Response, e.response
    assert_equal response.error, e.response.error
  end

  private

  def xml(raw)
    REXML::Document.new(raw)
  end

end
