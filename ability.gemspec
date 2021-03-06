Gem::Specification.new do |s|
  s.name = 'ability'
  s.version = '0.2.2'
  s.date = '2014-08-13'
  s.summary = 'Ability Access API Ruby Client'
  s.description = 'A Ruby client for interacting with the Ability ACCESS API'
  s.authors = ['consolochase@gmail.com', 'consolocoleman@gmail.com']
  s.email = 'consolocoleman@gmail.com'
  s.homepage = 'http://github.com/consolo/ability_client'
  s.files = Dir.glob('lib/**/*') + %w(README.md)
  s.add_dependency 'rest-client'
  s.add_dependency 'builder'
  s.add_dependency 'xml-simple'
  s.add_development_dependency 'webmock'
  s.require_paths = ['lib']
end
