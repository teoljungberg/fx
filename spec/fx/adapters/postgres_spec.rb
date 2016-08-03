require "spec_helper"

module Fx::Adapters
  describe Postgres, :db do
    describe "#create_function" do
      it "successfully creates a function" do
        postgres = Postgres.new
        postgres.create_function(
          <<~EOS
            CREATE OR REPLACE FUNCTION test()
            RETURNS text AS $$
            BEGIN
                RETURN 'test';
            END;
            $$ LANGUAGE plpgsql;
          EOS
        )

        expect(postgres.functions.map(&:name)).to include("test")
      end
    end

    describe "#create_trigger" do
      it "successfully creates a trigger" do
        connection.execute <<~EOS
          CREATE TABLE users (
              id int PRIMARY KEY,
              name varchar(256),
              upper_name varchar(256)
          );
        EOS
        postgres = Postgres.new
        postgres.create_function <<~EOS
          CREATE OR REPLACE FUNCTION uppercase_users_name()
          RETURNS trigger AS $$
          BEGIN
            NEW.upper_name = UPPER(NEW.name);
            RETURN NEW;
          END;
          $$ LANGUAGE plpgsql;
        EOS
        postgres.create_trigger(
          <<~EOS
            CREATE TRIGGER uppercase_users_name
                BEFORE INSERT ON users
                FOR EACH ROW
                EXECUTE PROCEDURE uppercase_users_name();
          EOS
        )

        expect(postgres.triggers.map(&:name)).to include("uppercase_users_name")
      end
    end

    describe "#drop_function" do
      it "successfully drops a function" do
        postgres = Postgres.new
        postgres.create_function(
          <<~EOS
            CREATE OR REPLACE FUNCTION test()
            RETURNS text AS $$
            BEGIN
                RETURN 'test';
            END;
            $$ LANGUAGE plpgsql;
          EOS
        )

        postgres.drop_function(:test)

        expect(postgres.functions.map(&:name)).not_to include("test")
      end
    end

    describe "#functions" do
      it "finds functions and builds Fx::Function objects" do
        postgres = Postgres.new
        postgres.create_function(
          <<~EOS
            CREATE OR REPLACE FUNCTION test()
            RETURNS text AS $$
            BEGIN
                RETURN 'test';
            END;
            $$ LANGUAGE plpgsql;
          EOS
        )

        expect(postgres.functions).to eq([
          Fx::Function.new(
            "name" => "test",
            "definition" => <<~EOS
              CREATE OR REPLACE FUNCTION public.test()
               RETURNS text
               LANGUAGE plpgsql
              AS $function$
              BEGIN
                  RETURN 'test';
              END;
              $function$
            EOS
          ),
        ])
      end
    end

    describe "#triggers" do
      it "finds triggers and builds Fx::Trigger objects" do
        connection.execute <<~EOS
          CREATE TABLE users (
              id int PRIMARY KEY,
              name varchar(256),
              upper_name varchar(256)
          );
        EOS
        postgres = Postgres.new
        postgres.create_function <<~EOS
          CREATE OR REPLACE FUNCTION uppercase_users_name()
          RETURNS trigger AS $$
          BEGIN
            NEW.upper_name = UPPER(NEW.name);
            RETURN NEW;
          END;
          $$ LANGUAGE plpgsql;
        EOS
        sql_definition = <<~EOS
          CREATE TRIGGER uppercase_users_name
              BEFORE INSERT ON users
              FOR EACH ROW
              EXECUTE PROCEDURE uppercase_users_name()
        EOS
        postgres.create_trigger(sql_definition)

        expect(postgres.triggers).to eq(
          [
            Fx::Trigger.new(
              "name" => "uppercase_users_name",
              "definition" => format_trigger(sql_definition),
            ),
          ],
        )
      end
    end

    def format_trigger(trigger)
      trigger.gsub("\n", "").gsub("    ", " ")
    end
  end
end
