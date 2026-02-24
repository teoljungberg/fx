require "spec_helper"

RSpec.describe Fx::FunctionsSortByDependency do
  describe ".call" do
    it "orders dependencies before dependents" do
      euclidean = function("euclidean", <<~SQL)
        CREATE OR REPLACE FUNCTION euclidean(a float[], b float[])
        RETURNS float AS $$
        BEGIN
            RETURN sqrt(vec_sub(a, b));
        END;
        $$ LANGUAGE plpgsql;
      SQL
      vec_sub = function("vec_sub", <<~SQL)
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
      distance = function("distance", <<~SQL)
        CREATE OR REPLACE FUNCTION distance(a float[], b float[])
        RETURNS float AS $$
        BEGIN
            RETURN sqrt(sum_squares(a, b));
        END;
        $$ LANGUAGE plpgsql;
      SQL
      sum_squares = function("sum_squares", <<~SQL)
        CREATE OR REPLACE FUNCTION sum_squares(a float[], b float[])
        RETURNS float AS $$
        BEGIN
            RETURN sum(square(a[i] - b[i]));
        END;
        $$ LANGUAGE plpgsql;
      SQL
      square = function("square", <<~SQL)
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
      is_even = function("is_even", <<~SQL)
        CREATE OR REPLACE FUNCTION is_even(n integer)
        RETURNS boolean AS $$
        BEGIN
            IF n = 0 THEN RETURN true; END IF;
            RETURN is_odd(n - 1);
        END;
        $$ LANGUAGE plpgsql;
      SQL
      is_odd = function("is_odd", <<~SQL)
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
      add = function("add", <<~SQL)
        CREATE OR REPLACE FUNCTION add(a integer, b integer)
        RETURNS integer AS $$
        BEGIN
            RETURN a + b;
        END;
        $$ LANGUAGE plpgsql;
      SQL
      multiply = function("multiply", <<~SQL)
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
      normalize = function("normalize", <<~SQL)
        CREATE OR REPLACE FUNCTION normalize(v float[])
        RETURNS float[] AS $$
        BEGIN
            RETURN normalize_vector(v);
        END;
        $$ LANGUAGE plpgsql;
      SQL
      normalize_vector = function("normalize_vector", <<~SQL)
        CREATE OR REPLACE FUNCTION normalize_vector(v float[])
        RETURNS float[] AS $$
        BEGIN
            RETURN v;
        END;
        $$ LANGUAGE plpgsql;
      SQL
      norm = function("norm", <<~SQL)
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

    it "handles overloaded function calls" do
      distance = function("distance", <<~SQL)
        CREATE OR REPLACE FUNCTION distance(a float[], b float[])
        RETURNS float AS $$
        BEGIN
            RETURN vec_sub(a, b) + vec_sub(b, a);
        END;
        $$ LANGUAGE plpgsql;
      SQL
      vec_sub = function("vec_sub", <<~SQL)
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
      calculate = function("calculate", <<~SQL)
        CREATE OR REPLACE FUNCTION calculate(x integer)
        RETURNS integer AS $$
        BEGIN
            -- used to call helper() here
            RETURN x * 2;
        END;
        $$ LANGUAGE plpgsql;
      SQL
      helper = function("helper", <<~SQL)
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
      calculate = function("calculate", <<~SQL)
        CREATE OR REPLACE FUNCTION calculate(x integer)
        RETURNS integer AS $$
        BEGIN
            /* previously called helper(x) for validation */
            RETURN x * 2;
        END;
        $$ LANGUAGE plpgsql;
      SQL
      helper = function("helper", <<~SQL)
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

    it "returns an empty array when given no functions" do
      result = described_class.call([])

      expect(result).to eq([])
    end

    def function(name, definition)
      Fx::Function.new("name" => name, "definition" => definition)
    end
  end
end
