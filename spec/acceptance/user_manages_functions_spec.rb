require "acceptance_helper"

describe "User manages functions" do
  it "handles simple functions" do
    successfully "rails generate fx:function test"
    write_function_definition "test_v01", <<-EOS
      CREATE OR REPLACE FUNCTION test()
      RETURNS text AS $$
      BEGIN
          RETURN 'test';
      END;
      $$ LANGUAGE plpgsql;
    EOS
    successfully "rake db:migrate"

    result = execute("SELECT * FROM test() AS result")
    expect(result).to eq("result" => "test")

    successfully "rails generate fx:function test"
    verify_identical_definitions(
      "db/functions/test_v01.sql",
      "db/functions/test_v02.sql",
    )
    write_function_definition "test_v02", <<-EOS
      CREATE OR REPLACE FUNCTION test()
      RETURNS text AS $$
      BEGIN
          RETURN 'testest';
      END;
      $$ LANGUAGE plpgsql;
    EOS
    successfully "rake db:migrate"

    result = execute("SELECT * FROM test() AS result")
    expect(result).to eq("result" => "testest")
  end

  it "handles functions with multiple signatures correctly" do
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

    successfully "rake db:schema:dump"
    connection.drop_function :test

    successfully "rake db:schema:load"

    result = execute("SELECT * FROM test() AS result")
    expect(result).to eq("result" => "test default")

    result = execute("SELECT * FROM test('non default') AS result")
    expect(result).to eq("result" => "non default")
  end
end
