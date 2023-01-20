require "spec_helper"
require "fx/statements/trigger"

describe Fx::Statements::Trigger, :db do
  describe "#create_trigger" do
    it "creates a trigger from a file" do
      database = stubbed_database
      definition = stubbed_definition

      connection.create_trigger(:test)

      expect(database).to have_received(:create_trigger)
        .with(definition.to_sql)
      expect(Fx::Definition).to have_received(:new)
        .with(name: :test, version: 1, type: "trigger")
    end

    it "allows creating a trigger with a specific version" do
      database = stubbed_database
      definition = stubbed_definition

      connection.create_trigger(:test, version: 2)

      expect(database).to have_received(:create_trigger)
        .with(definition.to_sql)
      expect(Fx::Definition).to have_received(:new)
        .with(name: :test, version: 2, type: "trigger")
    end

    it "raises an error if both arguments are set" do
      stubbed_database

      expect {
        connection.create_trigger(
          :whatever,
          version: 1,
          sql_definition: "a definition"
        )
      }.to raise_error(
        ArgumentError,
        /cannot both be set/
      )
    end
  end

  describe "#drop_trigger" do
    it "drops the trigger" do
      database = stubbed_database

      connection.drop_trigger(:test, on: :users)

      expect(database).to have_received(:drop_trigger)
        .with(:test, on: :users)
    end
  end

  describe "#update_trigger" do
    it "updates the trigger" do
      database = stubbed_database
      definition = stubbed_definition

      connection.update_trigger(:test, on: :users, version: 3)

      expect(database).to have_received(:update_trigger).with(
        :test,
        on: :users,
        sql_definition: definition.to_sql
      )
      expect(Fx::Definition).to have_received(:new).with(
        name: :test,
        version: 3,
        type: "trigger"
      )
    end

    it "updates a trigger from a text definition" do
      database = stubbed_database

      connection.update_trigger(
        :test,
        on: :users,
        sql_definition: "a definition"
      )

      expect(database).to have_received(:update_trigger).with(
        :test,
        on: :users,
        sql_definition: "a definition"
      )
    end

    it "raises an error if not supplied a version" do
      expect {
        connection.update_trigger(
          :whatever,
          version: nil,
          sql_definition: nil
        )
      }.to raise_error(
        ArgumentError,
        /version or sql_definition must be specified/
      )
    end

    it "raises an error if both arguments are set" do
      stubbed_database

      expect {
        connection.update_trigger(
          :whatever,
          version: 1,
          sql_definition: "a definition"
        )
      }.to raise_error(
        ArgumentError,
        /cannot both be set/
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
