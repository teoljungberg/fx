require "acceptance_helper"

RSpec.describe "User manages functions" do
  it "handles simple functions" do
    successfully "rails generate fx:function value"
    write_function_definition "value_v01", <<~SQL
      CREATE OR REPLACE FUNCTION value()
      RETURNS text AS $$
      BEGIN
          RETURN 'value';
      END;
      $$ LANGUAGE plpgsql;
    SQL
    successfully "rake db:migrate"

    result = execute("SELECT * FROM value() AS result")
    expect(result).to eq("result" => "value")

    successfully "rails generate fx:function value"
    verify_identical_definitions(
      "db/functions/value_v01.sql",
      "db/functions/value_v02.sql"
    )
    write_function_definition "value_v02", <<~SQL
      CREATE OR REPLACE FUNCTION value()
      RETURNS text AS $$
      BEGIN
          RETURN 'updated';
      END;
      $$ LANGUAGE plpgsql;
    SQL
    successfully "rake db:migrate"

    result = execute("SELECT * FROM value() AS result")
    expect(result).to eq("result" => "updated")
  end

  it "handles functions with arguments" do
    successfully "rails generate fx:function add"
    write_function_definition "add_v01", <<~SQL
      CREATE FUNCTION add(x int, y int)
      RETURNS int AS $$
      BEGIN
          RETURN $1 + $2;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    successfully "rake db:migrate"

    result = execute("SELECT * FROM add(1, 2) AS result")
    result["result"] = result["result"].to_i
    expect(result).to eq("result" => 3)

    successfully "rails destroy fx:function add"
    successfully "rake db:migrate"
  end
end
