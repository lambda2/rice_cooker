$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rice_cooker/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rice_cooker"
  s.version     = RiceCooker::VERSION
  s.authors     = ["Andre Aubin"]
  s.email       = ["andre@orga.42.fr"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of RiceCooker."
  s.description = "TODO: Description of RiceCooker."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.6"

  s.add_development_dependency "sqlite3"
end
