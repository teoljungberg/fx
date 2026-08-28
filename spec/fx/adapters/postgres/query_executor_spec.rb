require "spec_helper"

RSpec.describe Fx::Adapters::Postgres::QueryExecutor, :db do
  it "is an alias for Fx::Adapters::QueryExecutor" do
    expect(described_class).to be(Fx::Adapters::QueryExecutor)
  end
end
