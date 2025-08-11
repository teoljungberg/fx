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

      expect(functions.map(&:name)).to include("test")
      expect(functions.detect { |f| f.name == "test" }.definition).to eq(<<~EOS)
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

      connection.with schema_search_path: "other" do
        functions = Fx::Adapters::Postgres::Functions.new(connection).all

        expect(functions).to be_empty
      end
    end
  end
end
