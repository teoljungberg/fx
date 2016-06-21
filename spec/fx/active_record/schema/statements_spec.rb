require "spec_helper"
require "fx/active_record/schema/statements"

describe Fx::ActiveRecord::Schema::Statements, :db do
  describe "#create_function" do
    it "creates a function from a file" do
      function = <<~EOS
        CREATE OR REPLACE FUNCTION test() RETURNS text AS $$
        BEGIN
            RETURN 'test';
        END;
        $$ LANGUAGE plpgsql;
      EOS
      with_function_definition("test", function) do
        connection.create_function(:test)
        result = connection.execute("SELECT test() as result")

        expect(result).to include "result" => "test"
        expect(functions).to include "test"
      end
    end
  end

  describe "#drop_function" do
    it "drops the function" do
      function = <<~EOS
        CREATE OR REPLACE FUNCTION test() RETURNS text AS $$
        BEGIN
            RETURN 'test';
        END;
        $$ LANGUAGE plpgsql;
      EOS
      with_function_definition("test", function) do
        connection.create_function(:test)

        connection.drop_function(:test)

        expect(functions).not_to include "test"
        expect { connection.execute("SELECT test() as result") }.
          to raise_exception(ActiveRecord::StatementInvalid, /does not exist/)
      end
    end
  end

  def with_function_definition(name, definition)
    filename = ::Rails.root.join(
      "db",
      "functions",
      "#{name}.sql",
    )
    File.open(filename, "w") { |f| f.write(definition) }
    yield
  ensure
    File.delete filename
  end

  def functions
    connection.
      execute("SELECT proname FROM pg_proc").
      values.
      flatten
  end

  def connection
    @_connection ||= ActiveRecord::Base.connection
  end
end
