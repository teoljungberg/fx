require "spec_helper"

describe "Schema dump", :db do
  it "dumps a create_function for a function in the database" do
    definition = <<~EOS
      CREATE OR REPLACE FUNCTION test() RETURNS text AS $$
      BEGIN
          RETURN 'test';
      END;
    $$ LANGUAGE plpgsql;
    EOS
    with_function_definition(name: :test, definition: definition) do
      connection.create_function :test
      stream = StringIO.new

      ActiveRecord::SchemaDumper.dump(connection, stream)

      output = stream.string
      expect(output).to include "create_function :test"
      expect(output).to include "RETURN 'test';"
    end
  end
end
