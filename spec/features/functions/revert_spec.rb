require "spec_helper"

RSpec.describe "Reverting migrations", :db do
  around do |example|
    sql_definition = <<~SQL
      CREATE OR REPLACE FUNCTION value()
      RETURNS text AS $$
      BEGIN
          RETURN 'value';
      END;
      $$ LANGUAGE plpgsql;
    SQL
    with_function_definition(name: :value, sql_definition: sql_definition) do
      example.run
    end
  end

  it "can run reversible migrations for creating functions" do
    migration = Class.new(migration_class) do
      def change
        create_function :value
      end
    end

    expect { run_migration(migration, [:up, :down]) }.not_to raise_error
  end

  it "can run reversible migrations for dropping functions" do
    connection.create_function(:value)

    good_migration = Class.new(migration_class) do
      def change
        drop_function :value, revert_to_version: 1
      end
    end
    bad_migration = Class.new(migration_class) do
      def change
        drop_function :value
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
    connection.create_function(:value)

    sql_definition = <<~SQL
      CREATE OR REPLACE FUNCTION value()
      RETURNS text AS $$
      BEGIN
        RETURN 'bar';
      END;
      $$ LANGUAGE plpgsql;
    SQL
    with_function_definition(
      name: :value,
      version: 2,
      sql_definition: sql_definition
    ) do
      migration = Class.new(migration_class) do
        def change
          update_function :value, version: 2, revert_to_version: 1
        end
      end

      expect { run_migration(migration, [:up, :down]) }.not_to raise_error
    end
  end
end
