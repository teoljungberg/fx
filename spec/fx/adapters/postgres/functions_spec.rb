require "spec_helper"

RSpec.describe Fx::Adapters::Postgres::Functions, :db do
  describe ".all" do
    it "returns `Function` objects" do
      connection = ActiveRecord::Base.connection
      connection.execute <<~EOS
        CREATE OR REPLACE FUNCTION foo()
        RETURNS text AS $$
        BEGIN
            RETURN 'foo';
        END;
        $$ LANGUAGE plpgsql;
      EOS
      connection.execute <<~EOS
        CREATE OR REPLACE FUNCTION bar()
        RETURNS text AS $$
        BEGIN
            RETURN 'bar';
        END;
        $$ LANGUAGE plpgsql;
      EOS

      functions = Fx::Adapters::Postgres::Functions.new(connection).all

      first = functions.first
      second = functions.second
      expect(functions.size).to eq(2)
      expect(first.name).to eq("bar")
      expect(first.definition).to eq(<<~EOS)
        CREATE OR REPLACE FUNCTION public.bar()
         RETURNS text
         LANGUAGE plpgsql
        AS $function$
        BEGIN
            RETURN 'bar';
        END;
        $function$
      EOS
      expect(second.name).to eq("foo")
      expect(second.definition).to eq(<<~EOS)
        CREATE OR REPLACE FUNCTION public.foo()
         RETURNS text
         LANGUAGE plpgsql
        AS $function$
        BEGIN
            RETURN 'foo';
        END;
        $function$
      EOS

      connection.execute "CREATE SCHEMA IF NOT EXISTS other;"
      connection.execute "SET search_path = 'other';"

      functions = Fx::Adapters::Postgres::Functions.new(connection).all

      expect(functions).to be_empty
    end
  end
end
