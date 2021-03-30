require "spec_helper"

module Fx
  module Adapters
    describe Postgres::Functions, :db do
      describe ".all" do
        it "returns `Function` objects" do
          connection = ActiveRecord::Base.connection
          # We've got data bleeding between runs so we're doing some manual cleanup here as a stopgap.
          connection.execute <<-EOS.strip_heredoc
            DROP FUNCTION IF EXISTS adder CASCADE;
            DROP FUNCTION IF EXISTS uppercase_users_name CASCADE;
            CREATE OR REPLACE FUNCTION test()
            RETURNS text AS $$
            BEGIN
                RETURN 'test';
            END;
            $$ LANGUAGE plpgsql;
          EOS

          functions = Postgres::Functions.new(connection).all

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
  end
end
