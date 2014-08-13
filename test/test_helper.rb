require 'test/unit'
require 'webmock/test_unit'

class Test::Unit::TestCase

  # Get the path of a fixture given a path relative to fixtures
  def fixture_path(relative_path)
    File.expand_path(File.join(File.dirname(__FILE__), "fixtures", relative_path))
  end

  # Load a fixture
  def load_fixture(relative_path)
    File.read(File.new(fixture_path(relative_path)))
  end

  # Load an error response XML fixture
  def error_xml(fixture)
    load_xml(:errors, nil, fixture)
  end

  # Load a request XML fixture
  def request_xml(fixture, sub_fixture = nil)
    load_xml(fixture, sub_fixture, :request)
  end

  # Load a response XML fixture
  def response_xml(fixture, sub_fixture = nil)
    load_xml(fixture, sub_fixture, :response)
  end

  # Load XML from fixtures
  def load_xml(fixture, sub_fixture = nil, name)
    path = File.expand_path(File.join(File.dirname(__FILE__), "fixtures", fixture.to_s))
    
    if sub_fixture
      path = File.expand_path(File.join(path, sub_fixture.to_s))
    end

    xml_file = File.expand_path(File.join(path, "#{name.to_s}.xml"))

    File.read(File.new(xml_file))
  end
end
