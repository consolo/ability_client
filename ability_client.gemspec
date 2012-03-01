Gem::Specification.new do |s|
  s.name = "ability_client"
  s.version = "0.0.1"
  s.date = "2012-03-01"
  s.summary = "Ability Access API Ruby Client"
  s.authors = ["consolochase@gmail.com"]
  s.email = "consolochase@gmail.com"
  s.homepage = "http://github.com/consolo/ability_client"
  s.description = "Ability Access API Ruby Client"
  s.files = [
    "test/unit/ability_client_test.rb",
    "test/test_helper.rb",
    "test/support/claim_status_inquiry_request.xml",
    "test/support/password_change_request.xml",
    "test/support/password_change_response.xml",
    "test/support/service_list_response.xml",
    "test/support/eligibility_inquiry_response.xml",
    "test/support/claim_inquiry_response.xml",
    "test/support/claim_status_inquiry_response.xml",
    "test/support/eligibility_inquiry_request.xml",
    "test/support/claim_inquiry_request.xml",
    "Gemfile",
    "lib/ability/claim_inquiry.rb",
    "lib/ability/version.rb",
    "lib/ability/client.rb",
    "lib/ability.rb",
    "Gemfile.lock"
  ]
  s.require_paths = ["lib"]
end
