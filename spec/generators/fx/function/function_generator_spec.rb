require "spec_helper"
require "generators/fx/function/function_generator"

RSpec.describe Fx::Generators::FunctionGenerator, :generator do
  it "creates a function definition file, and a migration" do
    migration = file("db/migrate/create_function_test.rb")
    function_definition = file("db/functions/test_v01.sql")

    run_generator(described_class, ["test"])

    expect(function_definition).to exist
    expect_to_be_a_migration(migration)
    expect(migration_content(migration)).to include("CreateFunctionTest")
  end

  context "when passed --no-migration" do
    it "creates a only function definition file" do
      migration = file("db/migrate/create_function_test.rb")
      function_definition = file("db/functions/test_v01.sql")

      run_generator(described_class, ["test"], {migration: false})

      expect(function_definition).to exist
      expect(migration).not_to exist
    end
  end

  describe "helper predicates" do
    it "reports whether the function is new or existing" do
      generator = described_class.new(
        ["test"],
        {},
        destination_root: GeneratorSetup::RAILS_ROOT
      )

      expect(generator.send(:creating_new_function?)).to be(true)
      expect(generator.send(:updating_existing_function?)).to be(false)
    end
  end

  it "updates an existing function" do
    with_function_definition(
      name: "test",
      version: 1,
      sql_definition: "hello"
    ) do
      migration = file("db/migrate/update_function_test_to_version_2.rb")
      function_definition = file("db/functions/test_v02.sql")

      run_generator(described_class, ["test"])

      expect(function_definition).to exist
      expect_to_be_a_migration(migration)
      expect(migration_content(migration)).to include(
        "UpdateFunctionTestToVersion2"
      )
    end
  end
end
