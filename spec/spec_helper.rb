ENV["RAILS_ENV"] = "test"
require "database_cleaner"

require File.expand_path("../dummy/config/environment", __FILE__)
Dir["spec/support/**/*.rb"].sort.each { |file| load file }

RSpec.configure do |config|
  config.order = "random"
  DatabaseCleaner.strategy = :transaction
  DatabaseCleaner.clean_with :truncation

  config.around(:example, db: true) do |example|
    DatabaseCleaner.start
    example.run
    DatabaseCleaner.clean
  end

  unless defined?(silence_stream)
    require "active_support/testing/stream"
    config.include ActiveSupport::Testing::Stream
  end
end
