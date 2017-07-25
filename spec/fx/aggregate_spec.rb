require "spec_helper"
require "fx/aggregate"

module Fx
  describe Aggregate do
    describe "#<=>" do
      it "delegates to `name`" do
        aggregate_a = Aggregate.new("name" => "name_a")
        aggregate_b = Aggregate.new("name" => "name_b")
        aggregate_c = Aggregate.new("name" => "name_c")

        expect(aggregate_b).to be_between(aggregate_a, aggregate_c)
      end
    end

    describe "#==" do
      it "compares `name` and `definition`" do
        aggregate_a = Aggregate.new("name" => "name_a")
        aggregate_b = Aggregate.new("name" => "name_b")

        expect(aggregate_a).not_to eq(aggregate_b)
      end
    end

    describe "#to_schema" do
      it "returns a schema compatible version of the aggregate" do
        aggregate = Aggregate.new(
          "name" => "uppercase_users_name",
          "aggtransfn" => "array_append",
          "aggtranstype" => "anyelement"
        )

        expect(aggregate.to_schema).to eq <<-EOS
  create_aggregate :uppercase_users_name, sql_definition: <<-\SQL
      CREATE AGGREGATE uppercase_users_name()(
          SFUNC = array_append,
          STYPE = anyelement
      );
  SQL
        EOS
      end
    end
  end
end
