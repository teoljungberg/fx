require "spec_helper"

describe "Function migrations", :db do
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

  it "can run migrations that create functions" do
    migration = Class.new(migration_class) do
      def up
        create_function :test
      end
    end

    expect { run_migration(migration, :up) }.not_to raise_error
  end

  it "can run migrations that drop functions" do
    connection.create_function(:test)

    migration = Class.new(migration_class) do
      def up
        drop_function :test
      end
    end

    expect { run_migration(migration, :up) }.not_to raise_error
  end

  it "can run migrations that updates functions" do
    connection.create_function(:test)

    sql_definition = <<-EOS
      CREATE OR REPLACE FUNCTION test()
      RETURNS text AS $$
      BEGIN
          RETURN 'testest';
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

      expect { run_migration(migration, :change) }.not_to raise_error
    end
  end
end
