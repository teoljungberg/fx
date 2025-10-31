require "spec_helper"

RSpec.describe Fx::Adapters::Postgres::Triggers, :db do
  describe ".all" do
    it "returns `Trigger` objects" do
      connection = ActiveRecord::Base.connection
      connection.execute <<~SQL
        CREATE TABLE users (
            id int PRIMARY KEY,
            name varchar(256),
            upper_name varchar(256)
        );
      SQL
      connection.execute <<~SQL
        CREATE OR REPLACE FUNCTION uppercase_users_name()
        RETURNS trigger AS $$
        BEGIN
          NEW.upper_name = UPPER(NEW.name);
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      SQL
      connection.execute <<~SQL
        CREATE TRIGGER uppercase_users_name
            BEFORE INSERT ON users
            FOR EACH ROW
            EXECUTE FUNCTION uppercase_users_name();
      SQL

      triggers = Fx::Adapters::Postgres::Triggers.all(connection)

      first = triggers.first
      expect(triggers.size).to eq(1)
      expect(first.name).to eq("uppercase_users_name")
      expect(first.definition).to include("BEFORE INSERT")
      expect(first.definition).to match(/ON [public.ser|]/)
      expect(first.definition).to include("FOR EACH ROW")
      expect(first.definition).to include("EXECUTE FUNCTION uppercase_users_name()")

      connection.execute "CREATE SCHEMA IF NOT EXISTS other;"
      connection.execute "SET search_path = 'other';"

      triggers = Fx::Adapters::Postgres::Triggers.all(connection)

      expect(triggers).to be_empty
    end
  end
end
