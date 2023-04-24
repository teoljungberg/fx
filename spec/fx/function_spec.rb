require "spec_helper"

RSpec.describe Fx::Function do
  describe "#<=>" do
    it "delegates to `name`" do
      function_a = Fx::Function.new(
        "name" => "name_a",
        "definition" => "some definition"
      )
      function_b = Fx::Function.new(
        "name" => "name_b",
        "definition" => "some definition"
      )
      function_c = Fx::Function.new(
        "name" => "name_c",
        "definition" => "some definition"
      )

      expect(function_b).to be_between(function_a, function_c)
    end
  end

  describe "#==" do
    it "compares `name` and `definition`" do
      function_a = Fx::Function.new(
        "name" => "name_a",
        "definition" => "some definition"
      )
      function_b = Fx::Function.new(
        "name" => "name_b",
        "definition" => "some other definition"
      )

      expect(function_a).not_to eq(function_b)
    end
  end

  describe "#to_schema" do
    it "returns a schema compatible version of the function" do
      function = Fx::Function.new(
        "name" => "uppercase_users_name",
        "definition" => "CREATE OR REPLACE TRIGGER uppercase_users_name ..."
      )

      expect(function.to_schema).to eq <<-EOS
  create_function :uppercase_users_name, sql_definition: <<-'SQL'
      CREATE OR REPLACE TRIGGER uppercase_users_name ...
  SQL
      EOS
    end

    it "maintains backslashes" do
      function = Fx::Function.new(
        "name" => "regex",
        "definition" => "CREATE OR REPLACE FUNCTION regex \\1"
      )

      expect(function.to_schema).to eq <<-'EOS'
  create_function :regex, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION regex \1
  SQL
      EOS
    end
  end
end
