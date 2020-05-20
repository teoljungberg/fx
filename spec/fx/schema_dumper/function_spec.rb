require "spec_helper"

describe Fx::SchemaDumper::Function, :db do
  before do
    sql_definition = <<-EOS
      CREATE OR REPLACE FUNCTION my_function()
      RETURNS text AS $$
      BEGIN
          RETURN 'test';
      END;
      $$ LANGUAGE plpgsql;
    EOS
    connection.create_function :my_function, sql_definition: sql_definition
    connection.create_table :my_table

    ActiveRecord::SchemaDumper.dump(connection, stream)
  end

  let(:stream) { StringIO.new }
  let(:output) { stream.string }

  it "dumps a create_function for a function in the database" do
    expect(output).to match /create_table "my_table".*create_function :my_function.*RETURN 'test';/m
  end

  it "dumps a create_function for a function in the database", dump_functions_at_beginning_of_schema: true do
    expect(output).to match /create_function :my_function.*RETURN 'test';.*create_table "my_table"/m
  end
end
