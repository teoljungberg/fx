require "spec_helper"

RSpec.describe Fx::Configuration do
  it "defaults the database adapter to postgres" do
    expect(Fx.configuration.database).to be_a Fx::Adapters::Postgres
    expect(Fx.database).to be_a Fx::Adapters::Postgres
  end

  it "allows the database adapter to be set" do
    adapter = double("Fx Adapter")

    Fx.configure do |config|
      config.database = adapter
    end

    expect(Fx.configuration.database).to eq adapter
    expect(Fx.database).to eq adapter

    Fx.configuration = Fx::Configuration.new
  end
end
