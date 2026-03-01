require "acceptance_helper"

RSpec.describe "User manages functions" do
  it "handles simple functions" do
    successfully "rails generate fx:function test"
    write_function_definition "test_v01", <<~SQL
      CREATE OR REPLACE FUNCTION test()
      RETURNS text AS $$
      BEGIN
          RETURN 'test';
      END;
      $$ LANGUAGE plpgsql;
    SQL
    successfully "rake db:migrate"

    result = execute("SELECT * FROM test() AS result")
    expect(result).to eq("result" => "test")

    successfully "rails generate fx:function test"
    verify_identical_definitions(
      "db/functions/test_v01.sql",
      "db/functions/test_v02.sql"
    )
    write_function_definition "test_v02", <<~SQL
      CREATE OR REPLACE FUNCTION test()
      RETURNS text AS $$
      BEGIN
          RETURN 'testest';
      END;
      $$ LANGUAGE plpgsql;
    SQL
    successfully "rake db:migrate"

    result = execute("SELECT * FROM test() AS result")
    expect(result).to eq("result" => "testest")
  end

  it "handles functions with arguments" do
    successfully "rails generate fx:function adder"
    write_function_definition "adder_v01", <<~SQL
      CREATE FUNCTION adder(x int, y int)
      RETURNS int AS $$
      BEGIN
          RETURN $1 + $2;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    successfully "rake db:migrate"

    result = execute("SELECT * FROM adder(1, 2) AS result")
    result["result"] = result["result"].to_i
    expect(result).to eq("result" => 3)

    successfully "rails destroy fx:function adder"
    successfully "rake db:migrate"
  end

  it "handles updating functions with arguments" do
    successfully "rails generate fx:function multiply"
    write_function_definition "multiply_v01", <<~SQL
      CREATE FUNCTION multiply(x int, y int)
      RETURNS int AS $$
      BEGIN
          RETURN x * y;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    successfully "rake db:migrate"

    result = execute("SELECT * FROM multiply(3, 4) AS result")
    result["result"] = result["result"].to_i
    expect(result).to eq("result" => 12)

    successfully "rails generate fx:function multiply"
    write_function_definition "multiply_v02", <<~SQL
      CREATE FUNCTION multiply(x int, y int)
      RETURNS int AS $$
      BEGIN
          RETURN x * y * 2;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    successfully "rake db:migrate"

    result = execute("SELECT * FROM multiply(3, 4) AS result")
    result["result"] = result["result"].to_i
    expect(result).to eq("result" => 24)

    successfully "rake db:rollback"

    result = execute("SELECT * FROM multiply(3, 4) AS result")
    result["result"] = result["result"].to_i
    expect(result).to eq("result" => 12)

    successfully "rake db:rollback"

    expect { execute("SELECT * FROM multiply(3, 4) AS result") }
      .to raise_error(ActiveRecord::StatementInvalid)
  end

  it "handles dropping overloaded functions with explicit arguments" do
    successfully "rails generate fx:function inc"
    write_function_definition "inc_v01", <<~SQL
      CREATE FUNCTION inc(x int)
      RETURNS int AS $$
      BEGIN RETURN x + 1; END;
      $$ LANGUAGE plpgsql;
    SQL
    successfully "rake db:migrate"

    execute <<~SQL
      CREATE FUNCTION inc(x int, step int)
      RETURNS int AS $$ BEGIN RETURN x + step; END; $$ LANGUAGE plpgsql;
    SQL

    result = execute("SELECT inc(5) AS result")
    result["result"] = result["result"].to_i
    expect(result).to eq("result" => 6)

    result = execute("SELECT inc(5, 10) AS result")
    result["result"] = result["result"].to_i
    expect(result).to eq("result" => 15)

    write_migration "drop_inc_one_arg", <<~RUBY
      class DropIncOneArg < ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]
        def change
          drop_function :inc, arguments: "integer", revert_to_version: 1
        end
      end
    RUBY
    successfully "rake db:migrate"

    expect { execute("SELECT inc(5) AS result") }
      .to raise_error(ActiveRecord::StatementInvalid)

    result = execute("SELECT inc(5, 10) AS result")
    result["result"] = result["result"].to_i
    expect(result).to eq("result" => 15)

    successfully "rake db:rollback"

    result = execute("SELECT inc(5) AS result")
    result["result"] = result["result"].to_i
    expect(result).to eq("result" => 6)
  end
end
