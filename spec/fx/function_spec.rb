require "spec_helper"

RSpec.describe Fx::Function do
  describe "#<=>" do
    it "delegates to `signature`" do
      function_a = Fx::Function.new(
        "name" => "add",
        "definition" => "some definition",
        "arguments" => ""
      )
      function_b = Fx::Function.new(
        "name" => "make_incr",
        "definition" => "some definition",
        "arguments" => ""
      )
      function_c = Fx::Function.new(
        "name" => "value",
        "definition" => "some definition",
        "arguments" => ""
      )

      expect(function_b).to be_between(function_a, function_c)
    end

    it "orders overloads by signature" do
      add_int = Fx::Function.new(
        "name" => "add",
        "definition" => "some definition",
        "arguments" => "integer, integer"
      )
      add_text = Fx::Function.new(
        "name" => "add",
        "definition" => "some definition",
        "arguments" => "text, text"
      )

      expect(add_int <=> add_text).to be < 0
    end
  end

  describe "#==" do
    it "compares `signature` and `definition`" do
      function_a = Fx::Function.new(
        "name" => "add",
        "definition" => "some definition",
        "arguments" => ""
      )
      function_b = Fx::Function.new(
        "name" => "value",
        "definition" => "some other definition",
        "arguments" => ""
      )

      expect(function_a).not_to eq(function_b)
    end

    it "distinguishes overloads with the same name" do
      add_int = Fx::Function.new(
        "name" => "add",
        "definition" => "CREATE FUNCTION add(integer)",
        "arguments" => "integer"
      )
      add_text = Fx::Function.new(
        "name" => "add",
        "definition" => "CREATE FUNCTION add(text)",
        "arguments" => "text"
      )

      expect(add_int).not_to eq(add_text)
    end
  end

  describe "#signature" do
    it "returns name with arguments when arguments are present" do
      function = Fx::Function.new(
        "name" => "value",
        "definition" => "some definition",
        "arguments" => "integer"
      )

      expect(function.signature).to eq("value(integer)")
    end

    it "returns name with multiple arguments" do
      function = Fx::Function.new(
        "name" => "add",
        "definition" => "some definition",
        "arguments" => "integer, integer"
      )

      expect(function.signature).to eq("add(integer, integer)")
    end

    it "returns name with empty parens for no-arg functions" do
      function = Fx::Function.new(
        "name" => "value",
        "definition" => "some definition",
        "arguments" => ""
      )

      expect(function.signature).to eq("value()")
    end

    it "returns just the name when arguments key is missing" do
      function = Fx::Function.new(
        "name" => "value",
        "definition" => "some definition"
      )

      expect(function.signature).to eq("value")
    end
  end

  describe "#to_schema" do
    it "returns a schema compatible version of the function" do
      function = Fx::Function.new(
        "name" => "value",
        "definition" => "CREATE OR REPLACE FUNCTION value() ...",
        "arguments" => ""
      )

      expect(function.to_schema).to eq(<<-EOS)
  create_function :value, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION value() ...
  SQL
      EOS
    end

    it "maintains backslashes" do
      function = Fx::Function.new(
        "name" => "value",
        "definition" => "CREATE OR REPLACE FUNCTION value \\1",
        "arguments" => ""
      )

      expect(function.to_schema).to eq(<<-'EOS')
  create_function :value, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION value \1
  SQL
      EOS
    end
  end
end
