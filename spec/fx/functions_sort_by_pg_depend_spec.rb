require "spec_helper"

RSpec.describe Fx::FunctionsSortByPgDepend do
  describe ".call" do
    it "orders dependencies before dependents" do
      stub_pg_dependencies("euclidean" => ["vec_sub"])
      euclidean = function("euclidean")
      vec_sub = function("vec_sub")

      result = described_class.call([euclidean, vec_sub])

      expect(result).to eq([vec_sub, euclidean])
    end

    it "handles transitive dependencies" do
      stub_pg_dependencies(
        "distance" => ["sum_squares"],
        "sum_squares" => ["square"]
      )
      distance = function("distance")
      sum_squares = function("sum_squares")
      square = function("square")

      result = described_class.call([distance, sum_squares, square])

      expect(result).to eq([square, sum_squares, distance])
    end

    it "handles diamond dependencies" do
      stub_pg_dependencies(
        "top" => ["left", "right"],
        "left" => ["bottom"],
        "right" => ["bottom"]
      )
      top = function("top")
      left = function("left")
      right = function("right")
      bottom = function("bottom")

      result = described_class.call([top, left, right, bottom])

      expect(result.first).to eq(bottom)
      expect(result.last).to eq(top)
    end

    it "handles cycles gracefully" do
      stub_pg_dependencies(
        "is_even" => ["is_odd"],
        "is_odd" => ["is_even"]
      )
      is_even = function("is_even")
      is_odd = function("is_odd")

      result = described_class.call([is_even, is_odd])

      expect(result).to contain_exactly(is_even, is_odd)
    end

    it "preserves order when there are no dependencies" do
      stub_pg_dependencies({})
      add = function("add")
      multiply = function("multiply")

      result = described_class.call([add, multiply])

      expect(result).to eq([add, multiply])
    end

    it "ignores dependencies on functions not in the input list" do
      stub_pg_dependencies("calculate" => ["unknown_function"])
      calculate = function("calculate")

      result = described_class.call([calculate])

      expect(result).to eq([calculate])
    end

    it "returns an empty array when given no functions" do
      result = described_class.call([])

      expect(result).to eq([])
    end

    def function(name)
      Fx::Function.new(
        "name" => name,
        "definition" => "CREATE FUNCTION #{name}()"
      )
    end

    def stub_pg_dependencies(deps)
      rows = deps.flat_map do |dependent, dependencies|
        dependencies.map { |dep| [dependent, dep] }
      end

      result = ActiveRecord::Result.new(
        ["dependent", "dependency"],
        rows
      )

      connection = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      allow(connection).to receive(:exec_query).and_return(result)
      allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
    end
  end
end
