require "spec_helper"

describe "Schema dump", :db do
  it "dumps a create_function for a function in the database" do
    connection.create_function :test, sql_definition: <<~EOS
      CREATE OR REPLACE FUNCTION test() RETURNS text AS $$
      BEGIN
          RETURN 'test';
      END;
      $$ LANGUAGE plpgsql;
    EOS
    stream = StringIO.new

    ActiveRecord::SchemaDumper.dump(connection, stream)

    output = stream.string
    expect(output).to include "create_function :test"
    expect(output).to include "RETURN 'test';"
  end
end
