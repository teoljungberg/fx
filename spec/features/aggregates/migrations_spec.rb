require "spec_helper"

describe "Aggregate migrations", :db do
  around do |example|
    sql_definition = <<-EOS
      CREATE AGGREGATE test(anyelement)(
        sfunc = array_append,
        stype = anyarray,
        initcond = '{}'
      );
    EOS

    with_aggregate_definition(name: :test, sql_definition: sql_definition) do
      example.run
    end
  end

  it "can run migrations that create aggregates" do
    migration = Class.new(migration_class) do
      def up
        create_aggregate :test
      end
    end

    expect { run_migration(migration, :up) }.not_to raise_error
  end

  it "can run migrations that drop aggregates" do
    connection.create_aggregate(:test)

    migration = Class.new(migration_class) do
      def up
        drop_aggregate :test
      end
    end

    expect { run_migration(migration, :up) }.not_to raise_error
  end

  it "can run migrations that updates aggregates" do
    connection.create_aggregate(:test)

    sql_definition = <<-EOS
      CREATE AGGREGATE test(anyelement)(
        sfunc = array_append,
        stype = anyarray,
        initcond = '{}'
      );
    EOS

    with_aggregate_definition(
      name: :test,
      version: 2,
      sql_definition: sql_definition,
    ) do
      migration = Class.new(migration_class) do
        def change
          update_aggregate :test, version: 2, revert_to_version: 1
        end
      end

      expect { run_migration(migration, :change) }.not_to raise_error
    end
  end
end
