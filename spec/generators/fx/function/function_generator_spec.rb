require "spec_helper"
require "generators/fx/function/function_generator"

describe Fx::Generators::FunctionGenerator, :generator do
  it "creates a function definition file, and a migration" do
    migration = file("db/migrate/create_test.rb")
    function_definition = file("db/functions/test_v01.sql")

    run_generator ["test"]

    expect(function_definition).to exist
    expect(migration).to be_a_migration
    expect(migration_file(migration)).to contain "CreateTest"
  end

  it "updates an existing function" do
    allow(Dir).to receive(:entries).and_return(["test_v01.sql"])
    migration = file("db/migrate/update_test_to_version_2.rb")
    function_definition = file("db/functions/test_v02.sql")

    run_generator ["test"]

    expect(function_definition).to exist
    expect(migration).to be_a_migration
    expect(migration_file(migration)).to contain "UpdateTestToVersion2"
  end
end
