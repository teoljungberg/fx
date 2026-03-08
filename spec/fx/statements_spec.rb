require "spec_helper"

RSpec.describe Fx::Statements, :db do
  describe "#create_function" do
    it "creates a function from a file" do
      database = stubbed_database
      definition = stubbed_definition

      connection.create_function(:add)

      expect(database).to have_received(:create_function)
        .with(definition.to_sql)
      expect(Fx::Definition).to have_received(:function)
        .with(name: :add, version: 1)
    end

    it "allows creating a function with a specific version" do
      database = stubbed_database
      definition = stubbed_definition

      connection.create_function(:add, version: 2)

      expect(database).to have_received(:create_function)
        .with(definition.to_sql)
      expect(Fx::Definition).to have_received(:function)
        .with(name: :add, version: 2)
    end

    it "raises an error if both arguments are nil" do
      expect do
        connection.create_function(
          :whatever,
          version: nil,
          sql_definition: nil
        )
      end.to raise_error(
        ArgumentError,
        /version or sql_definition must be specified/
      )
    end
  end

  describe "#drop_function" do
    it "drops the function" do
      database = stubbed_database

      connection.drop_function(:add)

      expect(database).to have_received(:drop_function).with(:add)
    end
  end

  describe "#update_function" do
    it "updates the function" do
      database = stubbed_database
      definition = stubbed_definition

      connection.update_function(:add, version: 3)

      expect(database).to have_received(:update_function)
        .with(:add, definition.to_sql)
      expect(Fx::Definition).to have_received(:function)
        .with(name: :add, version: 3)
    end

    it "updates a function from a text definition" do
      database = stubbed_database

      connection.update_function(:add, sql_definition: "a definition")

      expect(database).to have_received(:update_function)
        .with(:add, "a definition")
    end

    it "raises an error if not supplied a version" do
      expect do
        connection.update_function(
          :whatever,
          version: nil,
          sql_definition: nil
        )
      end.to raise_error(
        ArgumentError,
        /version or sql_definition must be specified/
      )
    end
  end

  describe "#create_trigger" do
    it "creates a trigger from a file" do
      database = stubbed_database
      definition = stubbed_definition

      connection.create_trigger(:add)

      expect(database).to have_received(:create_trigger)
        .with(definition.to_sql)
      expect(Fx::Definition).to have_received(:trigger)
        .with(name: :add, version: 1)
    end

    it "allows creating a trigger with a specific version" do
      database = stubbed_database
      definition = stubbed_definition

      connection.create_trigger(:add, version: 2)

      expect(database).to have_received(:create_trigger)
        .with(definition.to_sql)
      expect(Fx::Definition).to have_received(:trigger)
        .with(name: :add, version: 2)
    end

    it "raises an error if both arguments are set" do
      stubbed_database

      expect do
        connection.create_trigger(
          :whatever,
          version: 1,
          sql_definition: "a definition"
        )
      end.to raise_error(
        ArgumentError,
        /cannot both be set/
      )
    end
  end

  describe "#drop_trigger" do
    it "drops the trigger" do
      database = stubbed_database

      connection.drop_trigger(:add, on: :users)

      expect(database).to have_received(:drop_trigger)
        .with(:add, on: :users)
    end
  end

  describe "#update_trigger" do
    it "updates the trigger" do
      database = stubbed_database
      definition = stubbed_definition

      connection.update_trigger(:add, on: :users, version: 3)

      expect(database).to have_received(:update_trigger).with(
        :add,
        on: :users,
        sql_definition: definition.to_sql
      )
      expect(Fx::Definition).to have_received(:trigger).with(
        name: :add,
        version: 3
      )
    end

    it "updates a trigger from a text definition" do
      database = stubbed_database

      connection.update_trigger(
        :add,
        on: :users,
        sql_definition: "a definition"
      )

      expect(database).to have_received(:update_trigger).with(
        :add,
        on: :users,
        sql_definition: "a definition"
      )
    end

    it "raises an error if not supplied a version" do
      expect do
        connection.update_trigger(
          :whatever,
          on: :users,
          version: nil,
          sql_definition: nil
        )
      end.to raise_error(
        ArgumentError,
        /version or sql_definition must be specified/
      )
    end

    it "raises an error if both arguments are set" do
      stubbed_database

      expect do
        connection.update_trigger(
          :whatever,
          on: :users,
          version: 1,
          sql_definition: "a definition"
        )
      end.to raise_error(
        ArgumentError,
        /cannot both be set/
      )
    end
  end

  def stubbed_definition
    instance_double("Fx::Definition", to_sql: nil).tap do |stubbed_definition|
      allow(Fx::Definition).to receive(:function).and_return(stubbed_definition)
      allow(Fx::Definition).to receive(:trigger).and_return(stubbed_definition)
    end
  end

  def stubbed_database
    database = instance_spy("StubbedDatabase")
    allow(Fx).to receive(:database).and_return(database)

    database
  end
end
