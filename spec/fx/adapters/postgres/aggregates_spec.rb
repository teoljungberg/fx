require "spec_helper"

module Fx
  module Adapters
    describe Postgres::Aggregates, :db do
      describe ".all" do
        it "returns `Aggregate` objects" do
          connection = ActiveRecord::Base.connection
          connection.execute <<-EOS.strip_heredoc
            CREATE AGGREGATE test(anyelement)(
              sfunc = array_append,
              stype = anyarray,
              initcond = '{}'
            );
          EOS

          aggregates = Postgres::Aggregates.new(connection).all

          first = aggregates.first
          expect(aggregates.size).to eq 1
          expect(first.name).to eq "test"
          expect(first.arguments).to eq "anyelement"
          expect(first.definition).to \
            include(
              "aggtransfn"     => "array_append",
              "aggtranstype"   => "anyarray",
              "agginitval"     => "{}",
            )

          expect(first.to_schema).to eq <<-SCHEMA
  create_aggregate :test, sql_definition: <<-\SQL
      CREATE AGGREGATE test(anyelement)(
          SFUNC = array_append,
          STYPE = anyarray,
          INITCOND = '{}'
      );
  SQL
          SCHEMA
        end
      end
    end
  end
end
