require "spec_helper"
require "fx/function"

module Fx
  describe Function do
    describe "#<=>" do
      it "delegates to `name`" do
        function_a = Function.new(
          "name" => "name_a",
          "definition" => "some defintion",
        )
        function_b = Function.new(
          "name" => "name_b",
          "definition" => "some defintion",
        )
        function_c = Function.new(
          "name" => "name_c",
          "definition" => "some defintion",
        )

        expect(function_b).to be_between(function_a, function_c)
      end
    end

    describe "#==" do
      it "compares `name` and `definition`" do
        function_a = Function.new(
          "name" => "name_a",
          "definition" => "some defintion",
        )
        function_b = Function.new(
          "name" => "name_b",
          "definition" => "some other defintion",
        )

        expect(function_a).not_to eq(function_b)
      end
    end

    describe "#signature" do
      it "returns the function signature" do
        function_a = Function.new(
          "name" => "test",
          "definition" => "some definition",
        )
        function_b = Function.new(
          "name" => "test",
          "arguments" => "anyarray, anyelement",
          "definition" => "some definition",
        )

        expect(function_a.signature).to eq("test()")
        expect(function_b.signature).to eq("test(anyarray, anyelement)")
      end
    end

    describe "#to_schema" do
      it "returns a schema compatible version of the function" do
        function = Function.new(
          "name" => "uppercase_users_name",
          "definition" => "CREATE OR REPLACE TRIGGER uppercase_users_name ...",
        )

        expect(function.to_schema).to eq <<-EOS
  create_function :uppercase_users_name, sql_definition: <<-\SQL
      CREATE OR REPLACE TRIGGER uppercase_users_name ...
  SQL
        EOS
      end
    end
  end
end
