require "spec_helper"
require "fx/statements/function"

describe Fx::Statements::Function, :db do
  describe "#create_function" do
    it "creates a function from a file" do
      database = stubbed_database
      definition = stubbed_definition

      connection.create_function(:test)

      expect(database).to have_received(:create_function)
        .with(definition.to_sql)
      expect(Fx::Definition).to have_received(:new)
        .with(name: :test, version: 1)
    end

    it "allows creating a function with a specific version" do
      database = stubbed_database
      definition = stubbed_definition

      connection.create_function(:test, version: 2)

      expect(database).to have_received(:create_function)
        .with(definition.to_sql)
      expect(Fx::Definition).to have_received(:new)
        .with(name: :test, version: 2)
    end

    it "raises an error if both arguments are nil" do
      expect {
        connection.create_function(
          :whatever,
          version: nil,
          sql_definition: nil
        )
      }.to raise_error(
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
      expect(Fx::Definition).to have_received(:new)
        .with(name: :test, version: 3)
    end

    it "updates a function from a text definition" do
      database = stubbed_database

      connection.update_function(:test, sql_definition: "a definition")

      expect(database).to have_received(:update_function).with(
        :test,
        "a definition"
      )
    end

    it "raises an error if not supplied a version" do
      expect {
        connection.update_function(
          :whatever,
          version: nil,
          sql_definition: nil
        )
      }.to raise_error(
        ArgumentError,
        /version or sql_definition must be specified/
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
