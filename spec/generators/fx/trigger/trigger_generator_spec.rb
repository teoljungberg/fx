require "spec_helper"
require "generators/fx/trigger/trigger_generator"

RSpec.describe Fx::Generators::TriggerGenerator, :generator do
  it "creates a trigger definition file, and a migration" do
    migration = file("db/migrate/create_trigger_test.rb")
    trigger_definition = file("db/triggers/test_v01.sql")

    run_generator(
      described_class,
      ["test", {"table_name" => "some_table"}]
    )

    expect(trigger_definition).to exist
    expect_to_be_a_migration(migration)
    expect(migration_content(migration)).to include("CreateTriggerTest")
    expect(migration_content(migration)).to include("on: :some_table")
  end

  context "when passed --no-migration" do
    it "creates a only trigger definition file" do
      migration = file("db/migrate/create_trigger_test.rb")
      trigger_definition = file("db/triggers/test_v01.sql")

      run_generator(
        described_class,
        ["test", {"table_name" => "some_table"}],
        {migration: false}
      )

      expect(trigger_definition).to exist
      expect(migration).not_to exist
    end
  end

  it "supports naming the table as `on` aswell as `table_name`" do
    migration = file("db/migrate/create_trigger_test.rb")
    trigger_definition = file("db/triggers/test_v01.sql")

    run_generator(
      described_class,
      ["test", {"on" => "some_table"}]
    )

    expect(trigger_definition).to exist
    expect_to_be_a_migration(migration)
    expect(migration_content(migration)).to include("CreateTriggerTest")
    expect(migration_content(migration)).to include("on: :some_table")
  end

  it "requires `table_name` or `on` to be specified" do
    expect do
      run_generator(
        described_class,
        ["test", {"foo" => "some_table"}]
      )
    end.to raise_error(ArgumentError)
  end

  it "updates an existing trigger" do
    allow(Dir).to receive(:entries).and_return(["test_v01.sql"])
    migration = file("db/migrate/update_trigger_test_to_version_2.rb")
    trigger_definition = file("db/triggers/test_v02.sql")

    run_generator(
      described_class,
      ["test", {"table_name" => "some_table"}]
    )

    expect(trigger_definition).to exist
    expect_to_be_a_migration(migration)
    expect(migration_content(migration)).to include("UpdateTriggerTestToVersion2")
    expect(migration_content(migration)).to include("on: :some_table")
  end
end
