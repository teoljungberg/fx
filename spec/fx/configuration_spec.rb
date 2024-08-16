require "spec_helper"

RSpec.describe Fx::Configuration do
  it "defaults the database adapter to postgres" do
    configuration = Fx::Configuration.new

    expect(configuration.database).to be_a(Fx::Adapters::Postgres)
  end

  it "defaults `dump_functions_at_beginning_of_schema` to false" do
    configuration = Fx::Configuration.new

    expect(configuration.dump_functions_at_beginning_of_schema).to eq(false)
  end

  it "allows the database adapter to be set" do
    configuration = Fx::Configuration.new
    adapter = double("Fx Adapter")

    configuration.database = adapter

    expect(configuration.database).to eq(adapter)
  end

  it "allows `dump_functions_at_beginning_of_schema` to be set" do
    configuration = Fx::Configuration.new

    configuration.dump_functions_at_beginning_of_schema = true

    expect(configuration.dump_functions_at_beginning_of_schema).to eq(true)
  end
end
