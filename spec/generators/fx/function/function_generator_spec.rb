require "spec_helper"
require "generators/fx/function/function_generator"

describe Fx::Generators::FunctionGenerator, :generator do
  it "creates a funciton definition file" do
    run_generator ["test"]
    function_definition = file("db/functions/test_v1.sql")
    expect(function_definition).to exist
  end

  it "creates a migration to create the function" do
    run_generator ["test"]
    migration = file("db/migrate/create_test.rb")
    expect(migration).to be_a_migration
  end
end
