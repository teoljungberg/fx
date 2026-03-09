require "spec_helper"

RSpec.describe Fx::FunctionsSortByDefinition do
  describe ".call" do
    it "orders dependencies before dependents" do
      euclidean = Fx::Function.new("name" => "euclidean", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION euclidean(a float[], b float[])
        RETURNS float AS $$
        BEGIN
            RETURN sqrt(vec_sub(a, b));
        END;
        $$ LANGUAGE plpgsql;
      SQL
      vec_sub = Fx::Function.new("name" => "vec_sub", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION vec_sub(a float[], b float[])
        RETURNS float[] AS $$
        BEGIN
            RETURN array_agg(a[i] - b[i]);
        END;
        $$ LANGUAGE plpgsql;
      SQL

      result = described_class.call([euclidean, vec_sub])

      expect(result).to eq([vec_sub, euclidean])
    end

    it "handles transitive dependencies" do
      distance = Fx::Function.new("name" => "distance", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION distance(a float[], b float[])
        RETURNS float AS $$
        BEGIN
            RETURN sqrt(sum_squares(a, b));
        END;
        $$ LANGUAGE plpgsql;
      SQL
      sum_squares = Fx::Function.new("name" => "sum_squares", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION sum_squares(a float[], b float[])
        RETURNS float AS $$
        BEGIN
            RETURN sum(square(a[i] - b[i]));
        END;
        $$ LANGUAGE plpgsql;
      SQL
      square = Fx::Function.new("name" => "square", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION square(x float)
        RETURNS float AS $$
        BEGIN
            RETURN x * x;
        END;
        $$ LANGUAGE plpgsql;
      SQL

      result = described_class.call([distance, sum_squares, square])

      expect(result).to eq([square, sum_squares, distance])
    end

    it "handles cycles gracefully" do
      is_even = Fx::Function.new("name" => "is_even", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION is_even(n integer)
        RETURNS boolean AS $$
        BEGIN
            IF n = 0 THEN RETURN true; END IF;
            RETURN is_odd(n - 1);
        END;
        $$ LANGUAGE plpgsql;
      SQL
      is_odd = Fx::Function.new("name" => "is_odd", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION is_odd(n integer)
        RETURNS boolean AS $$
        BEGIN
            IF n = 0 THEN RETURN false; END IF;
            RETURN is_even(n - 1);
        END;
        $$ LANGUAGE plpgsql;
      SQL

      result = described_class.call([is_even, is_odd])

      expect(result).to contain_exactly(is_even, is_odd)
    end

    it "preserves order when there are no dependencies" do
      add = Fx::Function.new("name" => "add", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION add(a integer, b integer)
        RETURNS integer AS $$
        BEGIN
            RETURN a + b;
        END;
        $$ LANGUAGE plpgsql;
      SQL
      multiply = Fx::Function.new("name" => "multiply", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION multiply(a integer, b integer)
        RETURNS integer AS $$
        BEGIN
            RETURN a * b;
        END;
        $$ LANGUAGE plpgsql;
      SQL

      result = described_class.call([add, multiply])

      expect(result).to eq([add, multiply])
    end

    it "does not match substring function names" do
      normalize = Fx::Function.new("name" => "normalize", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION normalize(v float[])
        RETURNS float[] AS $$
        BEGIN
            RETURN normalize_vector(v);
        END;
        $$ LANGUAGE plpgsql;
      SQL
      normalize_vector = Fx::Function.new("name" => "normalize_vector", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION normalize_vector(v float[])
        RETURNS float[] AS $$
        BEGIN
            RETURN v;
        END;
        $$ LANGUAGE plpgsql;
      SQL
      norm = Fx::Function.new("name" => "norm", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION norm(v float[])
        RETURNS float AS $$
        BEGIN
            RETURN 1.0;
        END;
        $$ LANGUAGE plpgsql;
      SQL

      result = described_class.call([normalize, normalize_vector, norm])

      expect(result).to eq([normalize_vector, normalize, norm])
    end

    it "handles multiple calls to the same dependency" do
      distance = Fx::Function.new("name" => "distance", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION distance(a float[], b float[])
        RETURNS float AS $$
        BEGIN
            RETURN vec_sub(a, b) + vec_sub(b, a);
        END;
        $$ LANGUAGE plpgsql;
      SQL
      vec_sub = Fx::Function.new("name" => "vec_sub", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION vec_sub(a float[], b float[])
        RETURNS float[] AS $$
        BEGIN
            RETURN a;
        END;
        $$ LANGUAGE plpgsql;
      SQL

      result = described_class.call([distance, vec_sub])

      expect(result).to eq([vec_sub, distance])
    end

    it "ignores function names in single-line comments" do
      calculate = Fx::Function.new("name" => "calculate", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION calculate(x integer)
        RETURNS integer AS $$
        BEGIN
            -- used to call helper() here
            RETURN x * 2;
        END;
        $$ LANGUAGE plpgsql;
      SQL
      helper = Fx::Function.new("name" => "helper", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION helper(x integer)
        RETURNS integer AS $$
        BEGIN
            RETURN x;
        END;
        $$ LANGUAGE plpgsql;
      SQL

      result = described_class.call([calculate, helper])

      expect(result).to eq([calculate, helper])
    end

    it "ignores function names in block comments" do
      calculate = Fx::Function.new("name" => "calculate", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION calculate(x integer)
        RETURNS integer AS $$
        BEGIN
            /* previously called helper(x) for validation */
            RETURN x * 2;
        END;
        $$ LANGUAGE plpgsql;
      SQL
      helper = Fx::Function.new("name" => "helper", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION helper(x integer)
        RETURNS integer AS $$
        BEGIN
            RETURN x;
        END;
        $$ LANGUAGE plpgsql;
      SQL

      result = described_class.call([calculate, helper])

      expect(result).to eq([calculate, helper])
    end

    it "does not match function names preceded by word characters" do
      process = Fx::Function.new("name" => "process", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION process(x integer)
        RETURNS integer AS $$
        BEGIN
            RETURN preprocess(x);
        END;
        $$ LANGUAGE plpgsql;
      SQL
      preprocess = Fx::Function.new("name" => "preprocess", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION preprocess(x integer)
        RETURNS integer AS $$
        BEGIN
            RETURN x;
        END;
        $$ LANGUAGE plpgsql;
      SQL

      result = described_class.call([process, preprocess])

      expect(result).to eq([preprocess, process])
    end

    it "does not confuse apostrophes in comments with string delimiters" do
      calculate = Fx::Function.new("name" => "calculate", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION calculate(x integer)
        RETURNS integer AS $$
        BEGIN
            -- don't call helper() anymore
            RETURN helper('value');
        END;
        $$ LANGUAGE plpgsql;
      SQL
      helper = Fx::Function.new("name" => "helper", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION helper(x text)
        RETURNS integer AS $$
        BEGIN
            RETURN 1;
        END;
        $$ LANGUAGE plpgsql;
      SQL

      result = described_class.call([calculate, helper])

      expect(result).to eq([helper, calculate])
    end

    it "treats all overloaded functions as dependencies when called by name" do
      add_integers = Fx::Function.new(
        "name" => "add",
        "definition" => <<~SQL,
          CREATE OR REPLACE FUNCTION add(a integer, b integer)
          RETURNS integer AS $$
          BEGIN
              RETURN a + b;
          END;
          $$ LANGUAGE plpgsql;
        SQL
        "arguments" => "a integer, b integer"
      )
      add_floats = Fx::Function.new(
        "name" => "add",
        "definition" => <<~SQL,
          CREATE OR REPLACE FUNCTION add(a float, b float)
          RETURNS float AS $$
          BEGIN
              RETURN a + b;
          END;
          $$ LANGUAGE plpgsql;
        SQL
        "arguments" => "a float, b float"
      )
      sum_three = Fx::Function.new("name" => "sum_three", "definition" => <<~SQL)
        CREATE OR REPLACE FUNCTION sum_three(x integer, y integer, z integer)
        RETURNS integer AS $$
        BEGIN
            RETURN add(add(x, y), z);
        END;
        $$ LANGUAGE plpgsql;
      SQL

      result = described_class.call([sum_three, add_integers, add_floats])

      expect(result).to eq([add_integers, add_floats, sum_three])
    end

    it "returns an empty array when given no functions" do
      result = described_class.call([])

      expect(result).to eq([])
    end
  end
end
