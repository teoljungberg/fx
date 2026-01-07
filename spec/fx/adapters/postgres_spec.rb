require "spec_helper"

RSpec.describe Fx::Adapters::Postgres, :db do
  describe "#create_function" do
    it "successfully creates a function" do
      adapter = Fx::Adapters::Postgres.new
      adapter.create_function(
        <<~SQL
          CREATE OR REPLACE FUNCTION test()
          RETURNS text AS $$
          BEGIN
              RETURN 'test';
          END;
          $$ LANGUAGE plpgsql;
        SQL
      )

      expect(adapter.functions.map(&:name)).to include("test")
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
        CREATE OR REPLACE FUNCTION uppercase_users_name()
        RETURNS trigger AS $$
        BEGIN
          NEW.upper_name = UPPER(NEW.name);
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      SQL
      adapter.create_trigger(
        <<~SQL
          CREATE TRIGGER uppercase_users_name
              BEFORE INSERT ON users
              FOR EACH ROW
              EXECUTE FUNCTION uppercase_users_name();
        SQL
      )

      expect(adapter.triggers.map(&:name)).to include("uppercase_users_name")
    end
  end

  describe "#drop_function" do
    context "when the function has arguments" do
      it "successfully drops a function with the entire function signature" do
        adapter = Fx::Adapters::Postgres.new
        adapter.create_function(
          <<~SQL
            CREATE FUNCTION adder(x int, y int)
            RETURNS int AS $$
            BEGIN
                RETURN $1 + $2;
            END;
            $$ LANGUAGE plpgsql;
          SQL
        )

        adapter.drop_function(:adder)

        expect(adapter.functions.map(&:name)).not_to include("adder")
      end
    end

    context "when the function does not have arguments" do
      it "successfully drops a function" do
        adapter = Fx::Adapters::Postgres.new
        adapter.create_function(
          <<~SQL
            CREATE OR REPLACE FUNCTION test()
            RETURNS text AS $$
            BEGIN
                RETURN 'test';
            END;
            $$ LANGUAGE plpgsql;
          SQL
        )

        adapter.drop_function(:test)

        expect(adapter.functions.map(&:name)).not_to include("test")
      end
    end
  end

  describe "#functions" do
    it "finds functions and builds Fx::Function objects" do
      adapter = Fx::Adapters::Postgres.new
      adapter.create_function(
        <<~SQL
          CREATE OR REPLACE FUNCTION test()
          RETURNS text AS $$
          BEGIN
              RETURN 'test';
          END;
          $$ LANGUAGE plpgsql;
        SQL
      )

      expect(adapter.functions.map(&:name)).to eq ["test"]
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
        CREATE OR REPLACE FUNCTION uppercase_users_name()
        RETURNS trigger AS $$
        BEGIN
          NEW.upper_name = UPPER(NEW.name);
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      SQL
      sql_definition = <<~SQL
        CREATE TRIGGER uppercase_users_name
            BEFORE INSERT ON users
            FOR EACH ROW
            EXECUTE FUNCTION uppercase_users_name()
      SQL
      adapter.create_trigger(sql_definition)

      expect(adapter.triggers.map(&:name)).to eq ["uppercase_users_name"]
    end
  end

  describe "#support_drop_function_without_args" do
    it "returns true for PostgreSQL version 10.0" do
      adapter = Fx::Adapters::Postgres.new
      connection = adapter.send(:connection)
      allow(connection).to receive(:server_version).and_return(10_00_00)

      result = connection.support_drop_function_without_args

      expect(result).to be(true)
    end

    it "returns true for PostgreSQL version 11.0" do
      adapter = Fx::Adapters::Postgres.new
      connection = adapter.send(:connection)
      allow(connection).to receive(:server_version).and_return(11_00_00)

      result = connection.support_drop_function_without_args

      expect(result).to be(true)
    end

    it "returns false for PostgreSQL version 9.6" do
      adapter = Fx::Adapters::Postgres.new
      connection = adapter.send(:connection)
      allow(connection).to receive(:server_version).and_return(9_06_00)

      result = connection.support_drop_function_without_args

      expect(result).to be(false)
    end

    it "returns false for PostgreSQL version 9.5" do
      adapter = Fx::Adapters::Postgres.new
      connection = adapter.send(:connection)
      allow(connection).to receive(:server_version).and_return(9_05_00)

      result = connection.support_drop_function_without_args

      expect(result).to be(false)
    end
  end

  describe "#supported_postgres_version?" do
    it "returns true for PostgreSQL 14 (minimum supported)" do
      adapter = Fx::Adapters::Postgres.new
      connection = adapter.send(:connection)
      allow(connection).to receive(:server_version).and_return(14_00_00)

      result = connection.supported_postgres_version?

      expect(result).to be(true)
    end

    it "returns true for PostgreSQL 18 (latest supported)" do
      adapter = Fx::Adapters::Postgres.new
      connection = adapter.send(:connection)
      allow(connection).to receive(:server_version).and_return(18_00_00)

      result = connection.supported_postgres_version?

      expect(result).to be(true)
    end

    it "returns false for PostgreSQL 13 (EOL)" do
      adapter = Fx::Adapters::Postgres.new
      connection = adapter.send(:connection)
      allow(connection).to receive(:server_version).and_return(13_00_00)

      result = connection.supported_postgres_version?

      expect(result).to be(false)
    end

    it "returns false for PostgreSQL 10" do
      adapter = Fx::Adapters::Postgres.new
      connection = adapter.send(:connection)
      allow(connection).to receive(:server_version).and_return(10_00_00)

      result = connection.supported_postgres_version?

      expect(result).to be(false)
    end
  end
end
