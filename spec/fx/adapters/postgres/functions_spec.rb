require "spec_helper"

module Fx
  module Adapters
    describe Postgres::Functions, :db do
      describe ".all" do
        it "returns `Function` objects" do
          connection = ActiveRecord::Base.connection
          connection.execute <<-SQL.strip_heredoc
            CREATE OR REPLACE FUNCTION test()
            RETURNS text AS $$
            BEGIN
                RETURN 'test';
            END;
            $$ LANGUAGE plpgsql;
          SQL

          functions = Postgres::Functions.new(connection).all

          first = functions.first
          expect(functions.size).to eq 1
          expect(first.name).to eq "test"
          expect(first.definition).to eq <<-SQL.strip_heredoc
            CREATE OR REPLACE FUNCTION public.test()
             RETURNS text
             LANGUAGE plpgsql
            AS $function$
            BEGIN
                RETURN 'test';
            END;
            $function$
          SQL
        end
      end
    end
  end
end
