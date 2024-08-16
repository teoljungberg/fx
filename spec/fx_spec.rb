require "spec_helper"

RSpec.describe Fx do
  it "has a version number" do
    expect(Fx::VERSION).to be_present
  end

  it "loads fx into ActiveRecord" do
    expect(ActiveRecord::Migration::CommandRecorder).to include(Fx::CommandRecorder)
    expect(ActiveRecord::ConnectionAdapters::AbstractAdapter).to include(Fx::Statements)
    expect(ActiveRecord::SchemaDumper).to include(Fx::SchemaDumper)
    expect(Fx.load).to eq(true)
  end

  it "allows configuration" do
    adapter = double("Fx Adapter")

    Fx.configure do |config|
      config.database = adapter
      config.dump_functions_at_beginning_of_schema = true
    end

    expect(Fx.configuration.database).to eq(adapter)
    expect(Fx.configuration.dump_functions_at_beginning_of_schema).to eq(true)

    Fx.configuration = nil
  end
end
