require "spec_helper"
require "fx/statements/view"

describe Fx::Statements::View, :db do
  describe "#create_view" do
    it "creates a view from a file" do
      database = stubbed_database
      definition = stubbed_definition

      connection.create_view(:test)

      expect(database).to have_received(:create_view)
        .with(definition.to_sql)
      expect(Fx::Definition).to have_received(:new)
        .with(name: :test, version: 1, type: "view")
    end

    it "allows creating a view with a specific version" do
      database = stubbed_database
      definition = stubbed_definition

      connection.create_view(:test, version: 2)

      expect(database).to have_received(:create_view)
        .with(definition.to_sql)
      expect(Fx::Definition).to have_received(:new)
        .with(name: :test, version: 2, type: "view")
    end

    it "raises an error if both arguments are nil" do
      expect {
        connection.create_view(
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

  describe "#drop_view" do
    it "drops the view" do
      database = stubbed_database

      connection.drop_view(:test)

      expect(database).to have_received(:drop_view).with(:test, materialized: false)
    end

    it "drops the materialzied view" do
      database = stubbed_database

      connection.drop_view(:test, materialized: true)

      expect(database).to have_received(:drop_view).with(:test, materialized: true)
    end
  end

  describe "#update_view" do
    it "updates the view" do
      database = stubbed_database
      definition = stubbed_definition

      connection.update_view(:test, version: 3)

      expect(database).to have_received(:update_view)
        .with(:test, definition.to_sql, materialized: false)
      expect(Fx::Definition).to have_received(:new)
        .with(name: :test, version: 3, type: "view")
    end

    it "updates a materialized view" do
      database = stubbed_database
      definition = stubbed_definition

      connection.update_view(:test, version: 3, materialized: true)

      expect(database).to have_received(:update_view)
        .with(:test, definition.to_sql, materialized: true)
      expect(Fx::Definition).to have_received(:new)
        .with(name: :test, version: 3, type: "view")
    end

    it "updates a view from a text definition" do
      database = stubbed_database

      connection.update_view(:test, sql_definition: "a definition")

      expect(database).to have_received(:update_view).with(
        :test,
        "a definition",
        materialized: false
      )
    end

    it "raises an error if not supplied a version" do
      expect {
        connection.update_view(
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
