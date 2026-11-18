require "spec_helper"

RSpec.describe "The public adapter interface", :db do
  it "dumps the functions and triggers the adapter returns" do
    adapter = RecordingAdapter.new
    adapter.functions = [
      Fx::Function.new(
        "name" => "greet",
        "definition" => "CREATE FUNCTION greet() RETURNS text LANGUAGE sql AS $$ SELECT 'hi' $$"
      )
    ]
    adapter.triggers = [
      Fx::Trigger.new(
        "name" => "greet_trigger",
        "definition" => "CREATE TRIGGER greet_trigger BEFORE INSERT ON greetings FOR EACH ROW EXECUTE FUNCTION greet()"
      )
    ]
    allow(Fx).to receive(:database).and_return(adapter)
    stream = StringIO.new

    ActiveRecord::SchemaDumper.dump(connection.pool, stream)

    expect(stream.string).to include("create_function :greet")
    expect(stream.string).to include("create_trigger :greet_trigger")
  end

  it "delegates the function statements to the adapter" do
    adapter = RecordingAdapter.new
    allow(Fx).to receive(:database).and_return(adapter)
    sql_definition = "CREATE FUNCTION greet() RETURNS text LANGUAGE sql AS $$ SELECT 'hi' $$"

    connection.create_function :greet, sql_definition: sql_definition
    connection.update_function :greet, sql_definition: sql_definition
    connection.drop_function :greet

    expect(adapter.statements).to eq([
      [:create_function, sql_definition],
      [:update_function, :greet, sql_definition],
      [:drop_function, :greet]
    ])
  end

  it "delegates the trigger statements to the adapter" do
    adapter = RecordingAdapter.new
    allow(Fx).to receive(:database).and_return(adapter)
    sql_definition = "CREATE TRIGGER greet_trigger BEFORE INSERT ON greetings FOR EACH ROW EXECUTE FUNCTION greet()"

    connection.create_trigger :greet_trigger, on: :greetings, sql_definition: sql_definition
    connection.update_trigger :greet_trigger, on: :greetings, sql_definition: sql_definition
    connection.drop_trigger :greet_trigger, on: :greetings

    expect(adapter.statements).to eq([
      [:create_trigger, sql_definition],
      [:update_trigger, :greet_trigger, :greetings, sql_definition],
      [:drop_trigger, :greet_trigger, :greetings]
    ])
  end
end

# Implements only the methods documented as the public adapter interface,
# so the specs above pin that set: anything core calls beyond it fails here.
class RecordingAdapter
  attr_writer :functions, :triggers
  attr_reader :statements

  def initialize
    @functions = []
    @triggers = []
    @statements = []
  end

  attr_reader :functions

  attr_reader :triggers

  def create_function(sql_definition)
    statements << [:create_function, sql_definition]
  end

  def drop_function(name)
    statements << [:drop_function, name]
  end

  def update_function(name, sql_definition)
    statements << [:update_function, name, sql_definition]
  end

  def create_trigger(sql_definition)
    statements << [:create_trigger, sql_definition]
  end

  def drop_trigger(name, on:)
    statements << [:drop_trigger, name, on]
  end

  def update_trigger(name, on:, sql_definition:)
    statements << [:update_trigger, name, on, sql_definition]
  end
end
