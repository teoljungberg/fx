require "spec_helper"
require "generators/fx/trigger/trigger_generator"

RSpec.describe Fx::Generators::TriggerGenerator, :generator do
  it "creates a trigger definition file, and a migration" do
    migration = file("db/migrate/create_trigger_set_upper_name.rb")
    trigger_definition = file("db/triggers/set_upper_name_v01.sql")

    run_generator(
      described_class,
      ["set_upper_name", {"table_name" => "users"}]
    )

    expect(trigger_definition).to exist
    expect_to_be_a_migration(migration)
    expect(migration_content(migration)).to include("CreateTriggerSetUpperName")
    expect(migration_content(migration)).to include("on: :users")
  end

  context "when passed --no-migration" do
    it "creates a only trigger definition file" do
      migration = file("db/migrate/create_trigger_set_upper_name.rb")
      trigger_definition = file("db/triggers/set_upper_name_v01.sql")

      run_generator(
        described_class,
        ["set_upper_name", {"table_name" => "users"}],
        {migration: false}
      )

      expect(trigger_definition).to exist
      expect(migration).not_to exist
    end
  end

  it "supports naming the table as `on` aswell as `table_name`" do
    migration = file("db/migrate/create_trigger_set_upper_name.rb")
    trigger_definition = file("db/triggers/set_upper_name_v01.sql")

    run_generator(
      described_class,
      ["set_upper_name", {"on" => "users"}]
    )

    expect(trigger_definition).to exist
    expect_to_be_a_migration(migration)
    expect(migration_content(migration)).to include("CreateTriggerSetUpperName")
    expect(migration_content(migration)).to include("on: :users")
  end

  it "requires `table_name` or `on` to be specified" do
    expect do
      run_generator(
        described_class,
        ["set_upper_name", {"foo" => "users"}]
      )
    end.to raise_error(ArgumentError)
  end

  it "updates an existing trigger" do
    with_trigger_definition(
      name: "set_upper_name",
      version: 1,
      sql_definition: "hello"
    ) do
      migration = file("db/migrate/update_trigger_set_upper_name_to_version_2.rb")
      trigger_definition = file("db/triggers/set_upper_name_v02.sql")

      run_generator(
        described_class,
        ["set_upper_name", {"table_name" => "users"}]
      )

      expect(trigger_definition).to exist
      expect_to_be_a_migration(migration)
      expect(migration_content(migration)).to include(
        "UpdateTriggerSetUpperNameToVersion2"
      )
      expect(migration_content(migration)).to include("on: :users")
    end
  end
end
