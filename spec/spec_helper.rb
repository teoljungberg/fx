ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment", __FILE__)
Dir["spec/support/**/*.rb"].sort.each { |file| load file }

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "fx"

RSpec.configure do |config|
  config.order = "random"
  config.disable_monkey_patching!

  config.define_derived_metadata(file_path: %r{spec/(fx|features)/}) do |metadata|
    metadata[:db] = true
  end

  test_database = nil

  config.before(:suite) do
    db_config = ActiveRecord::Base.connection_db_config.configuration_hash
    test_database = Fx::TestDatabase.new(db_config, template: "fx_test_template")
    test_database.create_template
  end

  config.around(:each, db: true) do |example|
    test_database.with_instance(reuse: true) do
      example.run
    end
  end

  config.after(:suite) do
    test_database&.shutdown
  end

  unless defined?(silence_stream)
    require "active_support/testing/stream"
    config.include ActiveSupport::Testing::Stream
  end
end
