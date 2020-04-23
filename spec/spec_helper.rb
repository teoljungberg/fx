ENV["RAILS_ENV"] = "test"
require "database_cleaner"

require File.expand_path("../dummy/config/environment", __FILE__)
Dir["spec/support/**/*.rb"].sort.each { |file| load file }

RSpec.configure do |config|
  config.order = "random"
  DatabaseCleaner.strategy = :transaction

  config.around(:each, db: true) do |example|
    DatabaseCleaner.start
    example.run
    DatabaseCleaner.clean
  end

  config.around(:each, dump_functions_at_beginning_of_schema: true) do |example|
    begin
      Fx.configuration.dump_functions_at_beginning_of_schema = true
      example.run
    ensure
      Fx.configuration.dump_functions_at_beginning_of_schema = false
    end
  end

  unless defined?(silence_stream)
    require "active_support/testing/stream"
    config.include ActiveSupport::Testing::Stream
  end
end
