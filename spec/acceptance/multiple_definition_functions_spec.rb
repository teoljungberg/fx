require "acceptance_helper"

describe "Multiple definition functions" do
  before(:each) do
    sql_definition = <<-EOS
      CREATE OR REPLACE FUNCTION test(str text)
      RETURNS text AS $$
      BEGIN
          RETURN str;
      END;

      $$ LANGUAGE plpgsql;
      CREATE OR REPLACE FUNCTION test()
      RETURNS text AS $$
      BEGIN
          RETURN test('test default');
      END;
      $$ LANGUAGE plpgsql;
    EOS
    connection.create_function :test, sql_definition: sql_definition
  end

  it "dumps the function's to the schema" do
    stream = StringIO.new
    ActiveRecord::SchemaDumper.dump(connection, stream)
    output = stream.string

    expect(output).to include "create_function :test, sql_definition: <<-SQL"
    expect(output).to include "RETURN str;"
    expect(output).to include "RETURN test('test default');"
  end

  it "loads the schema correctly" do
    successfully "rake db:schema:dump"
    connection.drop_function :test

    successfully "rake db:schema:load"

    result = execute("SELECT * FROM test() AS result")
    expect(result).to eq("result" => "test default")

    result = execute("SELECT * FROM test('non default') AS result")
    expect(result).to eq("result" => "non default")
  end
end
