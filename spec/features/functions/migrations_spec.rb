require "spec_helper"

RSpec.describe "Function migrations", :db do
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

  it "can run migrations that create functions" do
    migration = Class.new(migration_class) do
      def up
        create_function :value
      end
    end

    expect { run_migration(migration, :up) }.not_to raise_error
  end

  it "can run migrations that drop functions" do
    connection.create_function(:value)

    migration = Class.new(migration_class) do
      def up
        drop_function :value
      end
    end

    expect { run_migration(migration, :up) }.not_to raise_error
  end

  it "can run migrations that updates functions" do
    connection.create_function(:value)

    sql_definition = <<~SQL
      CREATE OR REPLACE FUNCTION value()
      RETURNS text AS $$
      BEGIN
          RETURN 'valueest';
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

      expect { run_migration(migration, :change) }.not_to raise_error
    end
  end
end
