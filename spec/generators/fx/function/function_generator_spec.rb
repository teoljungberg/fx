require "spec_helper"
require "generators/fx/function/function_generator"

RSpec.describe Fx::Generators::FunctionGenerator, :generator do
  it "creates a function definition file, and a migration" do
    migration = file("db/migrate/create_function_value.rb")
    function_definition = file("db/functions/value_v01.sql")

    run_generator(described_class, ["value"])

    expect(function_definition).to exist
    expect_to_be_a_migration(migration)
    expect(migration_content(migration)).to include("CreateFunctionValue")
  end

  context "when passed --no-migration" do
    it "creates a only function definition file" do
      migration = file("db/migrate/create_function_value.rb")
      function_definition = file("db/functions/value_v01.sql")

      run_generator(described_class, ["value"], {migration: false})

      expect(function_definition).to exist
      expect(migration).not_to exist
    end
  end

  it "updates an existing function" do
    with_function_definition(
      name: "value",
      version: 1,
      sql_definition: "hello"
    ) do
      migration = file("db/migrate/update_function_value_to_version_2.rb")
      function_definition = file("db/functions/value_v02.sql")

      run_generator(described_class, ["value"])

      expect(function_definition).to exist
      expect_to_be_a_migration(migration)
      expect(migration_content(migration)).to include(
        "UpdateFunctionValueToVersion2"
      )
    end
  end
end
