require "spec_helper"

RSpec.describe Fx::Adapters::Postgres, :db do
  describe "#create_function" do
    it "successfully creates a function" do
      adapter = Fx::Adapters::Postgres.new
      adapter.create_function(
        <<~SQL
          CREATE OR REPLACE FUNCTION value()
          RETURNS text AS $$
          BEGIN
              RETURN 'value';
          END;
          $$ LANGUAGE plpgsql;
        SQL
      )

      expect(adapter.functions.map(&:name)).to include("value")
    end
  end

  describe "#create_trigger" do
    it "successfully creates a trigger" do
      connection.execute <<~SQL
        CREATE TABLE users (
            id int PRIMARY KEY,
            name varchar(256),
            upper_name varchar(256)
        );
      SQL
      adapter = Fx::Adapters::Postgres.new
      adapter.create_function <<~SQL
        CREATE OR REPLACE FUNCTION set_upper_name()
        RETURNS trigger AS $$
        BEGIN
          NEW.upper_name = UPPER(NEW.name);
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      SQL
      adapter.create_trigger(
        <<~SQL
          CREATE TRIGGER set_upper_name
              BEFORE INSERT ON users
              FOR EACH ROW
              EXECUTE FUNCTION set_upper_name();
        SQL
      )

      expect(adapter.triggers.map(&:name)).to include("set_upper_name")
    end
  end

  describe "#drop_function" do
    context "when the function has arguments" do
      it "successfully drops a function with the entire function signature" do
        adapter = Fx::Adapters::Postgres.new
        adapter.create_function(
          <<~SQL
            CREATE FUNCTION add(x int, y int)
            RETURNS int AS $$
            BEGIN
                RETURN $1 + $2;
            END;
            $$ LANGUAGE plpgsql;
          SQL
        )

        adapter.drop_function(:add)

        expect(adapter.functions.map(&:name)).not_to include("add")
      end
    end

    context "when the function does not have arguments" do
      it "successfully drops a function" do
        adapter = Fx::Adapters::Postgres.new
        adapter.create_function(
          <<~SQL
            CREATE OR REPLACE FUNCTION value()
            RETURNS text AS $$
            BEGIN
                RETURN 'value';
            END;
            $$ LANGUAGE plpgsql;
          SQL
        )

        adapter.drop_function(:value)

        expect(adapter.functions.map(&:name)).not_to include("value")
      end
    end
  end

  describe "#functions" do
    it "finds functions and builds Fx::Function objects" do
      adapter = Fx::Adapters::Postgres.new
      adapter.create_function(
        <<~SQL
          CREATE OR REPLACE FUNCTION value()
          RETURNS text AS $$
          BEGIN
              RETURN 'value';
          END;
          $$ LANGUAGE plpgsql;
        SQL
      )

      expect(adapter.functions.map(&:name)).to eq ["value"]
    end
  end

  describe "#triggers" do
    it "finds triggers and builds Fx::Trigger objects" do
      connection.execute <<~SQL
        CREATE TABLE users (
            id int PRIMARY KEY,
            name varchar(256),
            upper_name varchar(256)
        );
      SQL
      adapter = Fx::Adapters::Postgres.new
      adapter.create_function <<~SQL
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
            EXECUTE FUNCTION set_upper_name()
      SQL
      adapter.create_trigger(sql_definition)

      expect(adapter.triggers.map(&:name)).to eq ["set_upper_name"]
    end
  end

  describe "#support_drop_function_without_args" do
    it "returns true for all supported PostgreSQL versions" do
      adapter = Fx::Adapters::Postgres.new
      connection = adapter.send(:connection)

      expect(connection.support_drop_function_without_args).to be(true)
    end
  end
end
