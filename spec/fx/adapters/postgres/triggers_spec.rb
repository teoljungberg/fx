require "spec_helper"

RSpec.describe Fx::Adapters::Postgres::Triggers, :db do
  describe ".all" do
    it "returns `Trigger` objects" do
      connection = ActiveRecord::Base.connection
      connection.execute <<~EOS
        CREATE TABLE users (
            id int PRIMARY KEY,
            name varchar(256),
            upper_name varchar(256)
        );
      EOS
      connection.execute <<~EOS
        CREATE OR REPLACE FUNCTION uppercase_users_name()
        RETURNS trigger AS $$
        BEGIN
          NEW.upper_name = UPPER(NEW.name);
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      EOS
      connection.execute <<~EOS
        CREATE TRIGGER uppercase_users_name
            BEFORE INSERT ON users
            FOR EACH ROW
            EXECUTE FUNCTION uppercase_users_name();
      EOS

      triggers = Fx::Adapters::Postgres::Triggers.new(connection).all

      first = triggers.first
      expect(triggers.size).to eq(1)
      expect(first.name).to eq("uppercase_users_name")
      expect(first.definition).to include("BEFORE INSERT")
      expect(first.definition).to match(/ON [public.ser|]/)
      expect(first.definition).to include("FOR EACH ROW")
      expect(first.definition).to include("EXECUTE FUNCTION uppercase_users_name()")

      connection.execute "CREATE SCHEMA IF NOT EXISTS other;"
      connection.execute "SET search_path = 'other';"

      triggers = Fx::Adapters::Postgres::Triggers.new(connection).all

      expect(triggers).to be_empty

      connection.execute "SET search_path TO DEFAULT;"
    end
  end
end
