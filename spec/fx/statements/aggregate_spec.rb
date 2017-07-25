require "spec_helper"
require "fx/statements/aggregate"

describe Fx::Statements::Aggregate, :db do
  describe "#create_aggregate" do
    it "creates a aggregate from a file" do
      database = stubbed_database
      definition = stubbed_definition

      connection.create_aggregate(:test)

      expect(database).to have_received(:create_aggregate).
        with(definition.to_sql)
      expect(Fx::Definition).to have_received(:new).
        with(name: :test, version: 1, type: "aggregate")
    end

    it "allows creating a aggregate with a specific version" do
      database = stubbed_database
      definition = stubbed_definition

      connection.create_aggregate(:test, version: 2)

      expect(database).to have_received(:create_aggregate).
        with(definition.to_sql)
      expect(Fx::Definition).to have_received(:new).
        with(name: :test, version: 2, type: "aggregate")
    end

    it "raises an error if both arguments are nil" do
      expect {
        connection.create_aggregate(
          :whatever,
          version: nil,
          sql_definition: nil,
        )
      }.to raise_error(
        ArgumentError,
        /version or sql_definition must be specified/,
      )
    end
  end

  describe "#drop_aggregate" do
    it "drops the aggregate" do
      database = stubbed_database

      connection.drop_aggregate(:test)

      expect(database).to have_received(:drop_aggregate).with(:test)
    end
  end

  describe "#update_aggregate" do
    it "updates the aggregate" do
      database = stubbed_database
      definition = stubbed_definition

      connection.update_aggregate(:test, version: 3)

      expect(database).to have_received(:update_aggregate).
        with(:test, definition.to_sql)
      expect(Fx::Definition).to have_received(:new).
        with(name: :test, version: 3, type: "aggregate")
    end

    it "updates a aggregate from a text definition" do
      database = stubbed_database

      connection.update_aggregate(:test, sql_definition: "a definition")

      expect(database).to have_received(:update_aggregate).with(
        :test,
        "a definition",
      )
    end

    it "raises an error if not supplied a version" do
      expect {
        connection.update_aggregate(
          :whatever,
          version: nil,
          sql_definition: nil,
        )
      }.to raise_error(
        ArgumentError,
        /version or sql_definition must be specified/,
      )
    end
  end

  def stubbed_database
    instance_spy("StubbedDatabase").tap do |stubbed_database|
      allow(Fx).to receive(:database).and_return(stubbed_database)
    end
  end

  def stubbed_definition
    instance_double("Fx::Definition", to_sql: nil).tap do |stubbed_definition|
      allow(Fx::Definition).to receive(:new).and_return(stubbed_definition)
    end
  end
end
