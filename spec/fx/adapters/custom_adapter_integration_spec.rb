require "spec_helper"

class DuckTypedAdapter
  attr_reader :created_functions, :created_triggers
  attr_reader :updated_functions, :updated_triggers
  attr_reader :dropped_functions, :dropped_triggers
  attr_writer :functions, :triggers

  def initialize
    @created_functions = []
    @created_triggers = []
    @updated_functions = []
    @updated_triggers = []
    @dropped_functions = []
    @dropped_triggers = []
    @functions = []
    @triggers = []
  end

  attr_reader :functions

  attr_reader :triggers

  def create_function(sql_definition)
    @created_functions << sql_definition
  end

  def create_trigger(sql_definition)
    @created_triggers << sql_definition
  end

  def update_function(name, sql_definition)
    @updated_functions << [name, sql_definition]
  end

  def update_trigger(name, on:, sql_definition:)
    @updated_triggers << [name, on, sql_definition]
  end

  def drop_function(name)
    @dropped_functions << name
  end

  def drop_trigger(name, on:)
    @dropped_triggers << [name, on]
  end
end

RSpec.describe Fx::TestAdapter, :db do
  it_behaves_like "an fx adapter"
end

RSpec.describe "Duck-typed adapter integration", :db do
  let(:duck_adapter) { DuckTypedAdapter.new }

  around do |example|
    original_database = Fx.configuration.database
    Fx.configuration.database = duck_adapter

    example.run
  ensure
    Fx.configuration.database = original_database
  end

  describe "function statements" do
    it "delegates create_function to a plain object" do
      sql_definition = "CREATE FUNCTION my_function() RETURNS text AS $$ BEGIN RETURN 'x'; END; $$ LANGUAGE plpgsql;"

      connection.create_function(:my_function, sql_definition: sql_definition)

      expect(duck_adapter.created_functions).to include(sql_definition)
    end

    it "delegates update_function to a plain object" do
      sql_definition = "CREATE OR REPLACE FUNCTION my_function() RETURNS text AS $$ BEGIN RETURN 'y'; END; $$ LANGUAGE plpgsql;"

      connection.update_function(:my_function, sql_definition: sql_definition)

      expect(duck_adapter.updated_functions).to include(
        [:my_function, sql_definition]
      )
    end

    it "delegates drop_function to a plain object" do
      connection.drop_function(:my_function, revert_to_version: 1)

      expect(duck_adapter.dropped_functions).to include(:my_function)
    end
  end

  describe "trigger statements" do
    before do
      connection.create_table(:users) do |t|
        t.string :name
      end
    end

    it "delegates create_trigger to a plain object" do
      sql_definition = "CREATE TRIGGER my_trigger BEFORE INSERT ON users FOR EACH ROW EXECUTE FUNCTION my_function();"

      connection.create_trigger(:my_trigger, sql_definition: sql_definition)

      expect(duck_adapter.created_triggers).to include(sql_definition)
    end

    it "delegates update_trigger to a plain object" do
      sql_definition = "CREATE TRIGGER my_trigger BEFORE INSERT ON users FOR EACH ROW EXECUTE FUNCTION my_function();"

      connection.update_trigger(
        :my_trigger,
        on: :users,
        sql_definition: sql_definition
      )

      expect(duck_adapter.updated_triggers).to include(
        [:my_trigger, :users, sql_definition]
      )
    end

    it "delegates drop_trigger to a plain object" do
      connection.drop_trigger(:my_trigger, on: :users, revert_to_version: 1)

      expect(duck_adapter.dropped_triggers).to include([:my_trigger, :users])
    end
  end

  describe "schema dumping" do
    it "uses a plain object for functions and triggers" do
      connection.create_table(:users) do |t|
        t.string :name
      end

      duck_adapter.functions = [
        Fx::Function.new(
          "name" => "my_function",
          "definition" => "CREATE OR REPLACE FUNCTION my_function() RETURNS text AS $$ BEGIN RETURN 'x'; END; $$ LANGUAGE plpgsql;"
        )
      ]
      duck_adapter.triggers = [
        Fx::Trigger.new(
          "name" => "my_trigger",
          "definition" => "CREATE TRIGGER my_trigger BEFORE INSERT ON users FOR EACH ROW EXECUTE FUNCTION my_function();"
        )
      ]

      stream = StringIO.new

      if Rails.version >= "7.2"
        ActiveRecord::SchemaDumper.dump(connection.pool, stream)
      else
        ActiveRecord::SchemaDumper.dump(connection, stream)
      end

      output = stream.string
      expect(output).to include("create_function :my_function")
      expect(output).to include("create_trigger :my_trigger")
    end
  end
end

RSpec.describe "Custom adapter integration", :db do
  let(:test_adapter) { Fx::TestAdapter.new }

  around do |example|
    original_database = Fx.configuration.database
    Fx.configuration.database = test_adapter

    example.run
  ensure
    Fx.configuration.database = original_database
  end

  describe "function statements" do
    it "delegates create_function to the configured adapter" do
      sql_definition = "CREATE FUNCTION my_function() RETURNS text AS $$ BEGIN RETURN 'x'; END; $$ LANGUAGE plpgsql;"

      connection.create_function(:my_function, sql_definition: sql_definition)

      expect(test_adapter.created_functions).to include(sql_definition)
    end

    it "delegates update_function to the configured adapter" do
      sql_definition = "CREATE OR REPLACE FUNCTION my_function() RETURNS text AS $$ BEGIN RETURN 'y'; END; $$ LANGUAGE plpgsql;"

      connection.update_function(:my_function, sql_definition: sql_definition)

      expect(test_adapter.updated_functions).to include(
        [:my_function, sql_definition]
      )
    end

    it "delegates drop_function to the configured adapter" do
      connection.drop_function(:my_function, revert_to_version: 1)

      expect(test_adapter.dropped_functions).to include(:my_function)
    end
  end

  describe "trigger statements" do
    before do
      connection.create_table(:users) do |t|
        t.string :name
      end
    end

    it "delegates create_trigger to the configured adapter" do
      sql_definition = "CREATE TRIGGER my_trigger BEFORE INSERT ON users FOR EACH ROW EXECUTE FUNCTION my_function();"

      connection.create_trigger(:my_trigger, sql_definition: sql_definition)

      expect(test_adapter.created_triggers).to include(sql_definition)
    end

    it "delegates update_trigger to the configured adapter" do
      sql_definition = "CREATE TRIGGER my_trigger BEFORE INSERT ON users FOR EACH ROW EXECUTE FUNCTION my_function();"

      connection.update_trigger(
        :my_trigger,
        on: :users,
        sql_definition: sql_definition
      )

      expect(test_adapter.updated_triggers).to include(
        [:my_trigger, :users, sql_definition]
      )
    end

    it "delegates drop_trigger to the configured adapter" do
      connection.drop_trigger(:my_trigger, on: :users, revert_to_version: 1)

      expect(test_adapter.dropped_triggers).to include([:my_trigger, :users])
    end
  end

  describe "schema dumping" do
    it "uses the configured adapter for functions and triggers" do
      connection.create_table(:users) do |t|
        t.string :name
      end

      test_adapter.functions = [
        Fx::Function.new(
          "name" => "my_function",
          "definition" => "CREATE OR REPLACE FUNCTION my_function() RETURNS text AS $$ BEGIN RETURN 'x'; END; $$ LANGUAGE plpgsql;"
        )
      ]
      test_adapter.triggers = [
        Fx::Trigger.new(
          "name" => "my_trigger",
          "definition" => "CREATE TRIGGER my_trigger BEFORE INSERT ON users FOR EACH ROW EXECUTE FUNCTION my_function();"
        )
      ]

      stream = StringIO.new

      if Rails.version >= "7.2"
        ActiveRecord::SchemaDumper.dump(connection.pool, stream)
      else
        ActiveRecord::SchemaDumper.dump(connection, stream)
      end

      output = stream.string
      expect(output).to include("create_function :my_function")
      expect(output).to include("create_trigger :my_trigger")
    end
  end
end
