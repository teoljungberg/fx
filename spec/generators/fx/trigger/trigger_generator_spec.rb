require "spec_helper"
require "generators/fx/trigger/trigger_generator"

describe Fx::Generators::TriggerGenerator, :generator do
  it "creates a trigger definition file, and a migration" do
    migration = file("db/migrate/create_trigger_test.rb")
    trigger_definition = file("db/triggers/test_v01.sql")

    run_generator ["test", "table_name" => "some_table"]

    expect(trigger_definition).to exist
    expect(migration).to be_a_migration
    expect(migration_file(migration)).to contain "CreateTriggerTest"
    expect(migration_file(migration)).to contain "on: :some_table"
  end

  context "when passed --no-migration" do
    it "creates a only trigger definition file" do
      migration = file("db/migrate/create_trigger_test.rb")
      trigger_definition = file("db/triggers/test_v01.sql")

      run_generator ["test", {"table_name" => "some_table"}, "--no-migration"]

      expect(trigger_definition).to exist
      expect(migration_file(migration)).not_to exist
    end
  end

  it "supports naming the table as `on` aswell as `table_name`" do
    migration = file("db/migrate/create_trigger_test.rb")
    trigger_definition = file("db/triggers/test_v01.sql")

    run_generator ["test", "on" => "some_table"]

    expect(trigger_definition).to exist
    expect(migration).to be_a_migration
    expect(migration_file(migration)).to contain "CreateTriggerTest"
    expect(migration_file(migration)).to contain "on: :some_table"
  end

  it "requires `table_name` or `on` to be specified" do
    expect {
      run_generator ["test", "foo" => "some_table"]
    }.to raise_error ArgumentError
  end

  it "updates an existing trigger" do
    allow(Dir).to receive(:entries).and_return(["test_v01.sql"])
    migration = file("db/migrate/update_trigger_test_to_version_2.rb")
    trigger_definition = file("db/triggers/test_v02.sql")

    run_generator ["test", "table_name" => "some_table"]

    expect(trigger_definition).to exist
    expect(migration).to be_a_migration
    expect(migration_file(migration)).to contain "UpdateTriggerTestToVersion2"
    expect(migration_file(migration)).to contain "on: :some_table"
  end

  it "creates a trigger on a schema-specified table" do
    migration = file("db/migrate/create_trigger_test.rb")
    trigger_definition = file("db/triggers/test_v01.sql")

    run_generator ["test", "table_name" => "foo.some_table"]

    expect(trigger_definition).to exist
    expect(migration).to be_a_migration
    expect(migration_file(migration)).to contain "CreateTriggerTest"
    expect(migration_file(migration)).to contain 'on: "foo.some_table"'
  end

  it "updates an existing trigger on a schema-specified table" do
    allow(Dir).to receive(:entries).and_return(["test_v01.sql"])
    migration = file("db/migrate/update_trigger_test_to_version_2.rb")
    trigger_definition = file("db/triggers/test_v02.sql")

    run_generator ["test", "table_name" => "foo.some_table"]

    expect(trigger_definition).to exist
    expect(migration).to be_a_migration
    expect(migration_file(migration)).to contain "UpdateTriggerTestToVersion2"
    expect(migration_file(migration)).to contain 'on: "foo.some_table"'
  end
end
