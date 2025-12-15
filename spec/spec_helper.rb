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

  config.before(:suite) do
    DatabaseReset.call
  end

  config.around(:each, db: true) do |example|
    DatabaseReset.call

    example.run

    DatabaseReset.call
  end

  unless defined?(silence_stream)
    require "active_support/testing/stream"
    config.include ActiveSupport::Testing::Stream
  end
end
