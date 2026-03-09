require "spec_helper"

RSpec.describe "Trigger migrations", :db do
  around do |example|
    connection.execute <<~SQL
      CREATE TABLE users (
          id int PRIMARY KEY,
          name varchar(256),
          upper_name varchar(256)
      );
    SQL
    Fx.database.create_function <<~SQL
      CREATE OR REPLACE FUNCTION set_upper_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.upper_name = UPPER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    sql_definition = <<~SQL
      CREATE TRIGGER set_upper_name
          BEFORE INSERT ON users
          FOR EACH ROW
          EXECUTE FUNCTION set_upper_name();
    SQL
    with_trigger_definition(
      name: :set_upper_name,
      sql_definition: sql_definition
    ) do
      example.run
    end
  end

  it "can run migrations that create triggers" do
    migration = Class.new(migration_class) do
      def up
        create_trigger :set_upper_name
      end
    end

    expect { run_migration(migration, :up) }.not_to raise_error
  end

  it "can run migrations that drop triggers" do
    connection.create_trigger(:set_upper_name)

    migration = Class.new(migration_class) do
      def up
        drop_trigger :set_upper_name, on: :users
      end
    end

    expect { run_migration(migration, :up) }.not_to raise_error
  end
end
