require "rack/test"
require "rspec"
require "webmock/rspec"

ENV["RACK_ENV"] = "test"

require File.expand_path "../../app.rb", __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app
    MetabaseToShopifyCounter
  end
end

# Configure test database connection
MetabaseToShopifyCounter.configure do |config|
  config.set :db, SQLite3::Database.new("test.db")
end

RSpec.configure do |config|
  config.include RSpecMixin

  # Clean up the test database before each test
  config.before(:each) do
    app.settings.db.execute("DELETE FROM urls")
    app.settings.db.execute("DELETE FROM numbers")
  end
end
