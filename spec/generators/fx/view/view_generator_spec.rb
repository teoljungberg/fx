require "spec_helper"
require "generators/fx/view/view_generator"

describe Fx::Generators::ViewGenerator, :generator do
  it "creates a view definition file, and a migration" do
    migration = file("db/migrate/create_view_test.rb")
    view_definition = file("db/views/test_v01.sql")

    run_generator ["test"]

    expect(view_definition).to exist
    expect(migration).to be_a_migration

    migration_file = migration_file(migration)
    expect(migration_file).to contain "CreateViewTest"
    expect(migration_file).to contain "create_view :test\n"
  end

  context "when passed --materialized" do
    it "creates a materialized view definition file" do
      migration = file("db/migrate/create_view_test.rb")
      view_definition = file("db/views/test_v01.sql")

      run_generator ["test", "--materialized"]

      expect(view_definition).to exist
      expect(migration).to be_a_migration

      migration_file = migration_file(migration)
      expect(migration_file).to contain "CreateViewTest"
      expect(migration_file).to contain "create_view :test, materialized: true\n"
    end
  end

  context "when passed --no-migration" do
    it "creates a only view definition file" do
      migration = file("db/migrate/create_view_test.rb")
      view_definition = file("db/views/test_v01.sql")

      run_generator ["test", "--no-migration"]

      expect(view_definition).to exist
      expect(migration_file(migration)).not_to exist
    end
  end

  it "updates an existing view" do
    with_view_definition(
      name: "test",
      version: 1,
      sql_definition: "hello",
    ) do
      allow(Dir).to receive(:entries).and_return(["test_v01.sql"])
      migration = file("db/migrate/update_view_test_to_version_2.rb")
      view_definition = file("db/views/test_v02.sql")

      run_generator ["test"]

      expect(view_definition).to exist
      expect(migration).to be_a_migration
      expect(migration_file(migration)).
        to contain("UpdateViewTestToVersion2")
    end
  end
end
