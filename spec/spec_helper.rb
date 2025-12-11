ENV["RAILS_ENV"] = "test"
require "database_cleaner"

require File.expand_path("../dummy/config/environment", __FILE__)
Dir["spec/support/**/*.rb"].sort.each { |file| load file }

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "fx"

RSpec.configure do |config|
  config.order = "random"
  config.disable_monkey_patching!

  DatabaseCleaner.strategy = :transaction

  config.define_derived_metadata(file_path: %r{spec/(fx|features)/}) do |metadata|
    metadata[:db] = true
  end

  config.before(:suite) do
    connection = ActiveRecord::Base.connection
    connection.execute("DROP SCHEMA IF EXISTS public CASCADE;")
    connection.execute("CREATE SCHEMA public;")
    connection.schema_search_path = "public"
  end

  config.around(:each, db: true) do |example|
    ActiveRecord::Base.connection.execute("SET search_path TO DEFAULT;")

    DatabaseCleaner.start
    example.run
    DatabaseCleaner.clean
  end

  unless defined?(silence_stream)
    require "active_support/testing/stream"
    config.include ActiveSupport::Testing::Stream
  end
end
