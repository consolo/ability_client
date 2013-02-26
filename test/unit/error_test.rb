require File.expand_path(File.join(File.dirname(__FILE__), "..", "test_helper"))
require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "ability"))

class AbilityErrorTest < Test::Unit::TestCase
  
  def setup
    @message = "The Medicare application password has expired for the user ID. Reset the password using a terminal emulator or contact the MAC for assistance."
    @error = Ability::Error.generate(Ability::Parser.parse(error_xml(:password_expired)))
  end

  def test_error_class_is_automatically_generated
    Ability.send(:remove_const, :PasswordExpired) if Ability.const_defined?(:PasswordExpired)
    assert !Ability.const_defined?("PasswordExpired")
    Ability::Error.generate(Ability::Parser.parse(error_xml(:password_expired)))
    assert Ability.const_defined?("PasswordExpired")
  end

  def test_error_contains_attributes
    assert_equal @message, @error.message
    assert_equal "PasswordExpired", @error.code
    details = { "userId" => "someuser", "application" => "???" }
    assert_equal details, @error.details
  end

  def test_error_is_raisable_as_exception
    assert_raises(Ability::PasswordExpired) do
      @error.raise
    end
  end

  def test_message_is_passed_along_to_exception
    @error.raise
  rescue Ability::PasswordExpired => e
    assert_equal @message, e.error.message
    assert_equal @message, e.message
  end

  def test_handles_html_404_messages
    error = Ability::Error.generate(Ability::Parser.parse(load_fixture("errors/404.html")))
    assert_equal "ResourceNotFound", error.code
    assert_equal "Problem accessing /portal/services.", error.message
    assert_equal nil, error.details
  end

end
