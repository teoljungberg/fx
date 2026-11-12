ENV["RAILS_ENV"] = "test"

if ENV["COVERAGE"]
  require "active_record"
  require "simplecov"
  require "simplecov_json_formatter"
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
  ])
  SimpleCov.start do
    skip "/spec/"
    skip "/vendor/"
    skip "lib/fx/version.rb"
    command_name ENV.fetch("SIMPLECOV_COMMAND_NAME", "RSpec")
    cover "lib/**/*.rb"
    minimum_coverage 100
  end

  # Active Record 8.2+ runs Fx::CommandRecorder; earlier versions run
  # Fx::CommandRecorder::Legacy. Only the active half can be covered.
  if ActiveRecord.gem_version >= Gem::Version.new("8.2.0.alpha")
    SimpleCov.skip "lib/fx/command_recorder/legacy.rb"
  else
    SimpleCov.skip "lib/fx/command_recorder.rb"
  end
end

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
