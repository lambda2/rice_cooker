$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rice_cooker/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rice_cooker"
  s.version     = RiceCooker::VERSION
  s.authors     = ["Andre Aubin"]
  s.email       = ["andre.aubin@lambdaweb.fr"]
  s.homepage    = "https://github.com/lambda2/rice_cooker"
  s.summary     = "A collection manager for Rails API's"
  s.description = "Handle pagination, sorting, filtering, searching, and ranging on Rails collections."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.6"
  s.add_dependency 'kaminari', '~> 0.17.0'
  s.add_dependency 'api-pagination', '~> 4.3.0'
  s.add_dependency 'has_scope', '~> 0.6'

  s.add_development_dependency "sqlite3"
  s.add_development_dependency 'rspec-rails', '~> 3.0'
  s.add_development_dependency 'mocha', '1.1.0'
  s.add_development_dependency 'ruby-prof', '0.15.8'
  s.add_development_dependency 'test-unit', '3.1.3'
  s.add_development_dependency 'rails-perftest', '0.0.6'
  s.add_development_dependency 'simplecov', '0.11.1'
  s.add_development_dependency "factory_girl_rails", "~> 4.0"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency 'faker', '1.6.1'
  s.add_development_dependency "pry"
  s.add_development_dependency 'derailed'
  s.add_development_dependency 'stackprof'
  s.add_development_dependency 'rubocop', '~> 0.40.0'
end

