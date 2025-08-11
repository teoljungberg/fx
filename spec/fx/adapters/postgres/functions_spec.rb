require "spec_helper"

RSpec.describe Fx::Adapters::Postgres::Functions, :db do
  describe ".all" do
    it "returns `Function` objects" do
      connection = ActiveRecord::Base.connection
      connection.execute <<~EOS
        CREATE OR REPLACE FUNCTION test()
        RETURNS text AS $$
        BEGIN
            RETURN 'test';
        END;
        $$ LANGUAGE plpgsql;
      EOS

      functions = Fx::Adapters::Postgres::Functions.new(connection).all

      first = functions.first
      expect(functions.size).to eq(1)
      expect(first.name).to eq("test")
      expect(first.definition).to eq(<<~EOS)
        CREATE OR REPLACE FUNCTION public.test()
         RETURNS text
         LANGUAGE plpgsql
        AS $function$
        BEGIN
            RETURN 'test';
        END;
        $function$
      EOS

      connection.execute "CREATE SCHEMA IF NOT EXISTS other;"
      connection.execute "SET search_path = 'other';"

      functions = Fx::Adapters::Postgres::Functions.new(connection).all

      expect(functions).to be_empty

      connection.execute "SET search_path = 'public';"
      connection.execute "DROP SCHEMA IF EXISTS other CASCADE;"
    end
  end
end
