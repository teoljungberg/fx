require "spec_helper"
require "generators/fx/function/function_generator"

describe Fx::Generators::FunctionGenerator, :generator do
  it "creates a function definition file, and a migration" do
    run_generator ["test"]

    migration = migration_file("db/migrate/create_test.rb")
    function_definition = file("db/functions/test_v01.sql")
    expect(migration).to be_a_migration
    expect(File.read(migration)).to include "CreateTest"
    expect(function_definition).to exist
  end

  it "updates an existing function" do
    allow(Dir).to receive(:entries).and_return(["test_v01.sql"])

    run_generator ["test"]

    migration = migration_file("db/migrate/update_test_to_version_2.rb")
    function_definition = file("db/functions/test_v02.sql")
    expect(migration).to be_a_migration
    expect(File.read(migration)).to include "UpdateTestToVersion2"
    expect(function_definition).to exist
  end
end
