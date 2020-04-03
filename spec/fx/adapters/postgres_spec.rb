require "spec_helper"

module Fx::Adapters
  describe Postgres, :db do
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

    describe "#update_function" do
      it "successfully updates a function" do
        allow(adapter).to receive(:drop_function)
        allow(adapter).to receive(:create_function)

        name = "test"
        sql_definition = <<-EOS
          CREATE OR REPLACE FUNCTION test()
          RETURNS text AS $$
          BEGIN
              RETURN 'test';
          END;
          $$ LANGUAGE plpgsql;
        EOS

        adapter = Postgres.new
        adapter.update_function(name, sql_definition)

        expect(adapter).to have_received(:drop_function).with(name)
        expect(adapter).to have_received(:create_function).with(sql_definition)
      end

      it "successfully replaces a function" do
        allow(adapter).to receive(:drop_function)
        allow(adapter).to receive(:create_function)

        name = "test"
        sql_definition = <<-EOS
          CREATE OR REPLACE FUNCTION test()
          RETURNS text AS $$
          BEGIN
              RETURN 'test';
          END;
          $$ LANGUAGE plpgsql;
        EOS

        adapter = Postgres.new
        adapter.update_function(name, sql_definition, replace: true)

        expect(adapter).not_to have_received(:drop_function)
        expect(adapter).to have_received(:create_function).with(sql_definition)
      end
    end

    describe "#create_trigger" do
      it "successfully creates a trigger" do
        connection.execute <<-EOS
          CREATE TABLE users (
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
            CREATE TRIGGER uppercase_users_name
                BEFORE INSERT ON users
                FOR EACH ROW
                EXECUTE PROCEDURE uppercase_users_name();
          EOS
        )

        expect(adapter.triggers.map(&:name)).to include("uppercase_users_name")
      end
    end

    describe "#drop_function" do
      context "when the function has arguments" do
        it "successfully drops a function with the entire function signature" do
          adapter = Postgres.new
          adapter.create_function(
            <<-EOS
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

        expect(adapter.functions.map(&:name)).to eq ["test"]
      end
    end

    describe "#triggers" do
      it "finds triggers and builds Fx::Trigger objects" do
        connection.execute <<-EOS
          CREATE TABLE users (
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
