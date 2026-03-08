require "spec_helper"

RSpec.describe Fx::FunctionsSortByCatalog do
  describe ".call" do
    it "orders dependencies before dependents" do
      create_function("value", arguments: "integer", body: "SELECT $1")
      create_function(
        "make_incr",
        arguments: "integer",
        body: "SELECT value($1) + 1"
      )
      make_incr = function("make_incr", arguments: "integer")
      value = function("value", arguments: "integer")

      result = described_class.call([make_incr, value])

      expect(result).to eq([value, make_incr])
    end

    it "handles transitive dependencies" do
      create_function("value", arguments: "integer", body: "SELECT $1")
      create_function(
        "add",
        arguments: "integer, integer",
        body: "SELECT value($1) + value($2)"
      )
      create_function(
        "make_incr",
        arguments: "integer",
        body: "SELECT add($1, 1)"
      )
      make_incr = function("make_incr", arguments: "integer")
      add = function("add", arguments: "integer, integer")
      value = function("value", arguments: "integer")

      result = described_class.call([make_incr, add, value])

      expect(result).to eq([value, add, make_incr])
    end

    it "handles diamond dependencies" do
      create_function("value", arguments: "integer", body: "SELECT $1")
      create_function(
        "double",
        arguments: "integer",
        body: "SELECT value($1) * 2"
      )
      create_function(
        "negate",
        arguments: "integer",
        body: "SELECT value($1) * -1"
      )
      create_function(
        "compute",
        arguments: "integer",
        body: "SELECT double($1) + negate($1)"
      )
      compute = function("compute", arguments: "integer")
      double = function("double", arguments: "integer")
      negate = function("negate", arguments: "integer")
      value = function("value", arguments: "integer")

      result = described_class.call([compute, double, negate, value])

      expect(result.first).to eq(value)
      expect(result.last).to eq(compute)
    end

    it "handles cycles gracefully" do
      # BEGIN ATOMIC bodies are parsed at creation, so we bootstrap
      # is_even with a dummy body, then replace it after is_odd exists.
      create_function(
        "is_even",
        returns: "boolean",
        arguments: "integer",
        body: "SELECT true"
      )
      create_function(
        "is_odd",
        returns: "boolean",
        arguments: "integer",
        body: "SELECT NOT is_even($1 - 1)"
      )
      create_function(
        "is_even",
        returns: "boolean",
        arguments: "integer",
        body: "SELECT NOT is_odd($1 - 1)"
      )
      is_even = function("is_even", arguments: "integer")
      is_odd = function("is_odd", arguments: "integer")

      result = described_class.call([is_even, is_odd])

      expect(result).to contain_exactly(is_even, is_odd)
    end

    it "preserves order when there are no dependencies" do
      create_function(
        "add",
        arguments: "integer, integer",
        body: "SELECT $1 + $2"
      )
      create_function(
        "multiply",
        arguments: "integer, integer",
        body: "SELECT $1 * $2"
      )
      add = function("add", arguments: "integer, integer")
      multiply = function("multiply", arguments: "integer, integer")

      result = described_class.call([add, multiply])

      expect(result).to eq([add, multiply])
    end

    it "ignores dependencies on functions not in the input list" do
      create_function("value", arguments: "integer", body: "SELECT $1")
      create_function(
        "make_incr",
        arguments: "integer",
        body: "SELECT value($1) + 1"
      )
      make_incr = function("make_incr", arguments: "integer")

      result = described_class.call([make_incr])

      expect(result).to eq([make_incr])
    end

    it "returns an empty array when given no functions" do
      result = described_class.call([])

      expect(result).to eq([])
    end

    it "distinguishes overloaded functions by signature" do
      create_function("value", arguments: "integer", body: "SELECT $1")
      create_function(
        "add",
        arguments: "integer, integer",
        body: "SELECT value($1) + $2"
      )
      create_function(
        "add",
        arguments: "text, text",
        returns: "text",
        body: "SELECT $1 || $2"
      )
      add_int = function("add", arguments: "integer, integer")
      add_text = function("add", arguments: "text, text")
      value = function("value", arguments: "integer")

      result = described_class.call([add_int, add_text, value])

      expect(result.index(value)).to be < result.index(add_int)
      expect(result).to include(add_text)
    end

    private

    def function(name, arguments: "")
      Fx::Function.new(
        "name" => name,
        "definition" => "CREATE FUNCTION #{name}()",
        "arguments" => arguments
      )
    end

    def create_function(name, body:, arguments: "", returns: "integer")
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE OR REPLACE FUNCTION #{name}(#{arguments})
        RETURNS #{returns}
        LANGUAGE SQL
        BEGIN ATOMIC
          #{body};
        END
      SQL
    end
  end
end
