require "spec_helper"

describe "View migrations", :db do
  around do |example|
    connection.execute <<-EOS
      CREATE TABLE users (
          id int PRIMARY KEY,
          name varchar(256),
          upper_name varchar(256),
          active boolean
      );
    EOS
    sql_definition = <<-EOS
      CREATE VIEW active_users AS
          SELECT * FROM users WHERE active = true;
    EOS
    with_view_definition(
      name: :active_users,
      sql_definition: sql_definition
    ) do
      example.run
    end
  end

  it "can run migrations that create views" do
    migration = Class.new(migration_class) do
      def up
        create_view :active_users
      end
    end

    expect { run_migration(migration, :up) }.not_to raise_error
  end

  it "can run migrations that drop views" do
    connection.create_view(:active_users)

    migration = Class.new(migration_class) do
      def up
        drop_view :active_users
      end
    end

    expect { run_migration(migration, :up) }.not_to raise_error
  end
end
