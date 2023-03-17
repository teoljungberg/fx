require "spec_helper"

describe "Reverting migrations", :db do
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

  it "can run reversible migrations for creating views" do
    migration = Class.new(migration_class) do
      def change
        create_view :active_users
      end
    end

    expect { run_migration(migration, [:up, :down]) }.not_to raise_error
  end

  it "can run reversible migrations for dropping views" do
    connection.create_view(:active_users)

    good_migration = Class.new(migration_class) do
      def change
        drop_view :active_users, revert_to_version: 1
      end
    end
    bad_migration = Class.new(migration_class) do
      def change
        drop_view :active_users
      end
    end

    expect { run_migration(good_migration, [:up, :down]) }.not_to raise_error
    expect { run_migration(bad_migration, [:up, :down]) }
      .to raise_error(
        ActiveRecord::IrreversibleMigration,
        /`create_view` is reversible only if given a `revert_to_version`/
      )
  end

  it "can run reversible migrations for updating views" do
    connection.create_view(:active_users)

    sql_definition = <<-EOS
      CREATE VIEW active_users AS
          SELECT id FROM users WHERE active = true;
    EOS
    with_view_definition(
      name: :active_users,
      sql_definition: sql_definition,
      version: 2
    ) do
      migration = Class.new(migration_class) do
        def change
          update_view(
            :active_users,
            version: 2,
            revert_to_version: 1
          )
        end
      end

      expect { run_migration(migration, [:up, :down]) }.not_to raise_error
    end
  end
end
