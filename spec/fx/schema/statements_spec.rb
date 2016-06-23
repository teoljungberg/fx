require "spec_helper"
require "fx/schema/statements"

describe Fx::Schema::Statements, :db do
  describe "#create_function" do
    it "creates a function from a file" do
      definition = <<~EOS
        CREATE OR REPLACE FUNCTION test() RETURNS text AS $$
        BEGIN
            RETURN 'test';
        END;
        $$ LANGUAGE plpgsql;
      EOS
      with_function_definition(name: "test", definition: definition) do
        connection.create_function(:test)
        result = connection.execute("SELECT test() as result")

        expect(result).to include "result" => "test"
        expect(functions).to include "test"
      end
    end

    it "allows creating a function with a specific version" do
      definition = <<~EOS
        CREATE OR REPLACE FUNCTION test() RETURNS text AS $$
        BEGIN
            RETURN 'test';
        END;
        $$ LANGUAGE plpgsql;
      EOS
      with_function_definition(
        name: "test",
        version: 2,
        definition: definition
      ) do
        connection.create_function(:test, version: 2)
        result = connection.execute("SELECT test() as result")

        expect(result).to include "result" => "test"
      end
    end

    it "raises an error if both arguments are nil" do
      expect {
        connection.create_function(
          :whatever,
          version: nil,
          sql_definition: nil,
        )
      }.to raise_error ArgumentError
    end
  end

  describe "#drop_function" do
    it "drops the function" do
      definition = <<~EOS
        CREATE OR REPLACE FUNCTION test() RETURNS text AS $$
        BEGIN
            RETURN 'test';
        END;
        $$ LANGUAGE plpgsql;
      EOS
      with_function_definition(name: "test", definition: definition) do
        connection.create_function(:test)

        connection.drop_function(:test)

        expect(functions).not_to include "test"
        expect { connection.execute("SELECT test() as result") }.
          to raise_exception(ActiveRecord::StatementInvalid, /does not exist/)
      end
    end
  end

  describe "#update_function" do
    it "updates the function" do
      definition_one = <<~EOS
        CREATE OR REPLACE FUNCTION test() RETURNS text AS $$
        BEGIN
            RETURN 'foo';
        END;
        $$ LANGUAGE plpgsql;
      EOS
      definition_two = <<~EOS
        CREATE OR REPLACE FUNCTION test() RETURNS text AS $$
        BEGIN
            RETURN 'bar';
        END;
        $$ LANGUAGE plpgsql;
      EOS
      with_function_definition(name: "test", definition: definition_one) do
        connection.create_function(:test)

        with_function_definition(
          name: "test",
          version: 2,
          definition: definition_two,
        ) do
          connection.update_function(:test, version: 2)

          result = connection.execute("SELECT test() as result")

          expect(result).to include "result" => "bar"
        end
      end
    end

    it "raises an error if not supplied a version" do
      expect { connection.update_function(:test) }.
        to raise_error(ArgumentError, /version is required/)
    end
  end

  def functions
    connection.
      execute("SELECT proname FROM pg_proc").
      values.
      flatten
  end
end
