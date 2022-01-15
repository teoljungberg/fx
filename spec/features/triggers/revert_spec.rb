require "spec_helper"

describe "Reverting migrations", :db do
  let(:table_name_prefix) { TABLE_NAME_PREFIX }
  let(:table_name_suffix) { TABLE_NAME_SUFFIX }

  def full_table_name(table_name)
    "#{table_name_prefix}#{table_name}#{table_name_suffix}"
  end

  around do |example|
    connection.execute <<-EOS
      CREATE TABLE "#{full_table_name('users')}" (
          id int PRIMARY KEY,
          name varchar(256),
          upper_name varchar(256)
      );
    EOS
    Fx.database.create_function <<-EOS
      CREATE OR REPLACE FUNCTION uppercase_users_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.upper_name = UPPER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    EOS
    sql_definition = <<-EOS
      CREATE TRIGGER uppercase_users_name
          BEFORE INSERT ON "#{full_table_name('users')}"
          FOR EACH ROW
          EXECUTE PROCEDURE uppercase_users_name();
    EOS
    with_trigger_definition(
      name: :uppercase_users_name,
      sql_definition: sql_definition,
    ) do
      example.run
    end
  end

  it "can run reversible migrations for creating triggers" do
    migration = Class.new(migration_class) do
      def change
        create_trigger :uppercase_users_name, on: :users
      end
    end

    expect { run_migration(migration, [:up, :down]) }.not_to raise_error
  end

  it "can run reversible migrations for dropping triggers" do
    connection.create_trigger(:uppercase_users_name, on: :users)

    good_migration = Class.new(migration_class) do
      def change
        drop_trigger :uppercase_users_name, on: :users, revert_to_version: 1
      end
    end
    bad_migration = Class.new(migration_class) do
      def change
        drop_trigger :uppercase_users_name, on: :users
      end
    end

    expect { run_migration(good_migration, [:up, :down]) }.not_to raise_error
    expect { run_migration(bad_migration, [:up, :down]) }.
      to raise_error(
        ActiveRecord::IrreversibleMigration,
        /`create_trigger` is reversible only if given a `revert_to_version`/,
      )
  end

  it "can run reversible migrations for updating triggers" do
    connection.create_trigger(:uppercase_users_name)

    sql_definition = <<-EOS
      CREATE TRIGGER uppercase_users_name
          BEFORE UPDATE ON "#{full_table_name('users')}"
          FOR EACH ROW
          EXECUTE PROCEDURE uppercase_users_name();
    EOS
    with_trigger_definition(
      name: :uppercase_users_name,
      sql_definition: sql_definition,
      version: 2,
    ) do
      migration = Class.new(migration_class) do
        def change
          update_trigger(
            :uppercase_users_name,
            on: :users,
            version: 2,
            revert_to_version: 1,
          )
        end
      end

      expect { run_migration(migration, [:up, :down]) }.not_to raise_error
    end
  end
end
