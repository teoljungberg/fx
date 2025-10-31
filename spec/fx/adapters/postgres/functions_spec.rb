require "spec_helper"

RSpec.describe Fx::Adapters::Postgres::Functions, :db do
  describe ".all" do
    it "returns `Function` objects" do
      connection = ActiveRecord::Base.connection
      connection.execute <<~SQL
        CREATE OR REPLACE FUNCTION test()
        RETURNS text AS $$
        BEGIN
            RETURN 'test';
        END;
        $$ LANGUAGE plpgsql;
      SQL

      functions = Fx::Adapters::Postgres::Functions.all(connection)

      first = functions.first
      expect(functions.size).to eq(1)
      expect(first.name).to eq("test")
      expect(first.definition).to eq(<<~SQL)
        CREATE OR REPLACE FUNCTION public.test()
         RETURNS text
         LANGUAGE plpgsql
        AS $function$
        BEGIN
            RETURN 'test';
        END;
        $function$
      SQL

      connection.execute "CREATE SCHEMA IF NOT EXISTS other;"
      connection.execute "SET search_path = 'other';"

      functions = Fx::Adapters::Postgres::Functions.all(connection)

      expect(functions).to be_empty
    end
  end
end
