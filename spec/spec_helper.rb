$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

begin
  require 'rails'
rescue LoadError
end

require 'bundler/setup'
Bundler.require
require 'rspec/active_model/mocks'

require 'mocks/mocks'
# if defined? ::Rails::Railtie
#   require 'rspec/rails'
# end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
# Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

  config.include Rack::Test::Methods
  config.include ControllerExampleGroup, :type => :controller
  
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate
end