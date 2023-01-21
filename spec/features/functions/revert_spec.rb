require "spec_helper"

describe "Reverting migrations", :db do
  around do |example|
    sql_definition = <<-EOS
      CREATE OR REPLACE FUNCTION test()
      RETURNS text AS $$
      BEGIN
          RETURN 'test';
      END;
      $$ LANGUAGE plpgsql;
    EOS
    with_function_definition(name: :test, sql_definition: sql_definition) do
      example.run
    end
  end

  it "can run reversible migrations for creating functions" do
    migration = Class.new(migration_class) do
      def change
        create_function :test
      end
    end

    expect { run_migration(migration, [:up, :down]) }.not_to raise_error
  end

  it "can run reversible migrations for dropping functions" do
    connection.create_function(:test)

    good_migration = Class.new(migration_class) do
      def change
        drop_function :test, revert_to_version: 1
      end
    end
    bad_migration = Class.new(migration_class) do
      def change
        drop_function :test
      end
    end

    expect { run_migration(good_migration, [:up, :down]) }.not_to raise_error
    expect { run_migration(bad_migration, [:up, :down]) }
      .to raise_error(
        ActiveRecord::IrreversibleMigration,
        /`create_function` is reversible only if given a `revert_to_version`/
      )
  end

  it "can run reversible migrations for updating functions" do
    connection.create_function(:test)

    sql_definition = <<-EOS
      CREATE OR REPLACE FUNCTION test()
      RETURNS text AS $$
      BEGIN
        RETURN 'bar';
      END;
      $$ LANGUAGE plpgsql;
    EOS
    with_function_definition(
      name: :test,
      version: 2,
      sql_definition: sql_definition
    ) do
      migration = Class.new(migration_class) do
        def change
          update_function :test, version: 2, revert_to_version: 1
        end
      end

      expect { run_migration(migration, [:up, :down]) }.not_to raise_error
    end
  end
end
