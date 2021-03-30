require "spec_helper"

module Fx::Adapters
  describe Postgres, :db do
    describe "#create_aggregate" do
      it "successfully creates an aggregate" do
        adapter = Postgres.new
        adapter.create_aggregate(
          <<-EOS
            CREATE OR REPLACE AGGREGATE test(anyelement)(
                SFUNC = array_append,
                STYPE = anyarray,
                INITCOND = '{}'
            );
          EOS
        )

        expect(adapter.aggregates.map(&:name)).to include("test")
      end
    end

    describe "#create_function" do
      it "successfully creates a function" do
        adapter = Postgres.new
        adapter.create_function(
          <<-EOS
            CREATE OR REPLACE FUNCTION test()
            RETURNS text AS $$
            BEGIN
                RETURN 'test';
            END;
            $$ LANGUAGE plpgsql;
          EOS
        )

        expect(adapter.functions.map(&:name)).to include("test")
      end
    end

    describe "#create_trigger" do
      it "successfully creates a trigger" do
        connection.execute <<-EOS
        CREATE TABLE IF NOT EXISTS users (
              id int PRIMARY KEY,
              name varchar(256),
              upper_name varchar(256)
          );
        EOS
        adapter = Postgres.new
        adapter.create_function <<-EOS
          CREATE OR REPLACE FUNCTION uppercase_users_name()
          RETURNS trigger AS $$
          BEGIN
            NEW.upper_name = UPPER(NEW.name);
            RETURN NEW;
          END;
          $$ LANGUAGE plpgsql;
        EOS
        adapter.create_trigger(
          <<-EOS
            DROP TRIGGER IF EXISTS uppercase_users_name ON users;
            CREATE TRIGGER uppercase_users_name
                BEFORE INSERT ON users
                FOR EACH ROW
                EXECUTE PROCEDURE uppercase_users_name();
          EOS
        )

        expect(adapter.triggers.map(&:name)).to include("uppercase_users_name")
      end
    end

    describe "#drop_aggregate" do
      it "successfully drops an aggregate" do
        adapter = Postgres.new
        adapter.create_aggregate(
          <<-EOS
            CREATE OR REPLACE AGGREGATE test(anyelement)(
                SFUNC = array_append,
                STYPE = anyarray,
                INITCOND = '{}'
            );
          EOS
        )

        adapter.drop_aggregate(:test)

        expect(adapter.aggregates.map(&:name)).not_to include("test")
      end
    end

    describe "#drop_function" do
      context "when the function has arguments" do
        it "successfully drops a function with the entire function signature" do
          adapter = Postgres.new
          adapter.create_function(
            <<-EOS
              DROP FUNCTION IF EXISTS adder;
              CREATE FUNCTION adder(x int, y int)
              RETURNS int AS $$
              BEGIN
                  RETURN $1 + $2;
              END;
              $$ LANGUAGE plpgsql;
            EOS
          )

          adapter.drop_function(:adder)

          expect(adapter.functions.map(&:name)).not_to include("adder")
        end
      end

      context "when the function does not have arguments" do
        it "successfully drops a function" do
          adapter = Postgres.new
          adapter.create_function(
            <<-EOS
              CREATE OR REPLACE FUNCTION test()
              RETURNS text AS $$
              BEGIN
                  RETURN 'test';
              END;
              $$ LANGUAGE plpgsql;
            EOS
          )

          adapter.drop_function(:test)

          expect(adapter.functions.map(&:name)).not_to include("test")
        end
      end
    end

    describe "#aggregates" do
      it "finds aggregates and builds Fx::Aggregate objects" do
        adapter = Postgres.new
        adapter.create_aggregate(
          <<-EOS
            CREATE OR REPLACE AGGREGATE test(anyelement)(
                SFUNC = array_append,
                STYPE = anyarray,
                INITCOND = '{}'
            );
          EOS
        )

        expect(adapter.aggregates.map(&:name)).to eq ["test"]
      end
    end

    describe "#functions" do
      it "finds functions and builds Fx::Function objects" do
        adapter = Postgres.new
        adapter.create_function(
          <<-EOS
            CREATE OR REPLACE FUNCTION test()
            RETURNS text AS $$
            BEGIN
                RETURN 'test';
            END;
            $$ LANGUAGE plpgsql;
          EOS
        )

        expect(adapter.functions.map(&:name)).to include("test")
      end
    end

    describe "#triggers" do
      it "finds triggers and builds Fx::Trigger objects" do
        connection.execute <<-EOS
        CREATE TABLE IF NOT EXISTS users (
              id int PRIMARY KEY,
              name varchar(256),
              upper_name varchar(256)
          );
        EOS
        adapter = Postgres.new
        adapter.create_function <<-EOS
          CREATE OR REPLACE FUNCTION uppercase_users_name()
          RETURNS trigger AS $$
          BEGIN
            NEW.upper_name = UPPER(NEW.name);
            RETURN NEW;
          END;
          $$ LANGUAGE plpgsql;
        EOS
        sql_definition = <<-EOS
          DROP TRIGGER IF EXISTS uppercase_users_name ON users;
          CREATE TRIGGER uppercase_users_name
              BEFORE INSERT ON users
              FOR EACH ROW
              EXECUTE PROCEDURE uppercase_users_name()
        EOS
        adapter.create_trigger(sql_definition)

        expect(adapter.triggers.map(&:name)).to eq ["uppercase_users_name"]
      end
    end
  end
end
