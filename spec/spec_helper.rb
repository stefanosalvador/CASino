# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'

require 'coveralls'
Coveralls.wear!

SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter '/spec'
end

require File.expand_path('../dummy/config/environment.rb', __FILE__)
require 'rspec/rails'
require 'rspec/its'
require 'webmock/rspec'
require 'couchrest_model'
require 'capybara/rails'

WebMock.disable_net_connect!(allow: 'http://localhost:5984')

ENGINE_RAILS_ROOT = File.join(File.dirname(__FILE__), '../')
puts ENGINE_RAILS_ROOT

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(ENGINE_RAILS_ROOT, 'spec/support/**/*.rb')].each { |f| require f }

COUCHHOST = ENV["COUCH_HOST"] || "http://127.0.0.1:5984"
TESTDB    = 'casino_test'
TEST_SERVER    = CouchRest.new COUCHHOST
DB = TEST_SERVER.database(TESTDB)

RSpec.configure do |config|
  config.before(:suite) do
    couch_uri = URI.parse(ENV['COUCH_HOST'] || "http://127.0.0.1:5984")
    CouchRest::Model::Base.configure do |c_config|
      c_config.connection  = {
        :protocol => couch_uri.scheme,
        :host     => couch_uri.host,
        :port     => couch_uri.port,
        :username => couch_uri.user,
        :password => couch_uri.password,
        :prefix   => "casino",
        :join     => "_",
        :suffix   => "test"
      }
    end
  end

  config.before(:each) { reset_test_db! }

end

def reset_test_db!
  DB.recreate!
  # Reset the Design Cache
  Thread.current[:couchrest_design_cache] = {}
  DB
end
