require "spec_helper"

RSpec.describe Fx::Adapters::Postgres::Functions, :db do
  describe ".all" do
    it "returns `Function` objects" do
      connection = ActiveRecord::Base.connection
      connection.execute <<-EOS.strip_heredoc
        CREATE OR REPLACE FUNCTION test()
        RETURNS text AS $$
        BEGIN
            RETURN 'test';
        END;
        $$ LANGUAGE plpgsql;
      EOS

      functions = Fx::Adapters::Postgres::Functions.new(connection).all

      first = functions.first
      expect(functions.size).to eq 1
      expect(first.name).to eq "test"
      expect(first.definition).to eq <<-EOS.strip_heredoc
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
  end
end
