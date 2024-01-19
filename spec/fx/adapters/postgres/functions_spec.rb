require "spec_helper"

RSpec.describe Fx::Adapters::Postgres::Functions, :db do
  describe ".all" do
    it "returns `Function` objects in all schemas" do
      connection = ActiveRecord::Base.connection
      connection.execute <<-EOS.strip_heredoc
        CREATE SCHEMA test_schema;
        CREATE OR REPLACE FUNCTION test()
        RETURNS text AS $$
        BEGIN
            RETURN 'test';
        END;
        $$ LANGUAGE plpgsql;
        CREATE OR REPLACE FUNCTION test_schema.test()
        RETURNS text AS $$
        BEGIN
            RETURN 'test';
        END;
        $$ LANGUAGE plpgsql;
      EOS

      functions = Fx::Adapters::Postgres::Functions.new(connection).all

      expect(functions.size).to eq 2
      functions.first.tap do |fx|
        expect(fx.name).to eq "test"
        expect(fx.definition).to eq <<-EOS.strip_heredoc
          CREATE OR REPLACE FUNCTION public.test()
           RETURNS text
           LANGUAGE plpgsql
          AS $function$
          BEGIN
              RETURN 'test';
          END;
          $function$
        EOS
      end

      functions.last.tap do |fx|
        expect(fx.name).to eq "test_schema.test"
        expect(fx.definition).to eq <<-EOS.strip_heredoc
          CREATE OR REPLACE FUNCTION test_schema.test()
           RETURNS text
           LANGUAGE plpgsql
          AS $function$
          BEGIN
              RETURN 'test';
          END;
          $function$
        EOS
      end
    end
  end
end
