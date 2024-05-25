require "spec_helper"

RSpec.describe Fx::Statements, :db do
  describe "#create_function" do
    it "creates a function from a file" do
      database = stubbed_database
      definition = stubbed_definition

      connection.create_function(:test)

      expect(database).to have_received(:create_function)
        .with(definition.to_sql)
      expect(Fx::Definition).to have_received(:function)
        .with(name: :test, version: 1)
    end

    it "allows creating a function with a specific version" do
      database = stubbed_database
      definition = stubbed_definition

      connection.create_function(:test, version: 2)

      expect(database).to have_received(:create_function)
        .with(definition.to_sql)
      expect(Fx::Definition).to have_received(:function)
        .with(name: :test, version: 2)
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

      connection.drop_function(:test)

      expect(database).to have_received(:drop_function).with(:test)
    end
  end

  describe "#update_function" do
    it "updates the function" do
      database = stubbed_database
      definition = stubbed_definition

      connection.update_function(:test, version: 3)

      expect(database).to have_received(:update_function)
        .with(:test, definition.to_sql)
      expect(Fx::Definition).to have_received(:function)
        .with(name: :test, version: 3)
    end

    it "updates a function from a text definition" do
      database = stubbed_database

      connection.update_function(:test, sql_definition: "a definition")

      expect(database).to have_received(:update_function)
        .with(:test, "a definition")
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

      connection.create_trigger(:test)

      expect(database).to have_received(:create_trigger)
        .with(definition.to_sql)
      expect(Fx::Definition).to have_received(:trigger)
        .with(name: :test, version: 1)
    end

    it "allows creating a trigger with a specific version" do
      database = stubbed_database
      definition = stubbed_definition

      connection.create_trigger(:test, version: 2)

      expect(database).to have_received(:create_trigger)
        .with(definition.to_sql)
      expect(Fx::Definition).to have_received(:trigger)
        .with(name: :test, version: 2)
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
      expect(Fx::Definition).to have_received(:trigger).with(
        name: :test,
        version: 3
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
      expect do
        connection.update_trigger(
          :whatever,
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
