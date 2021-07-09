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

  it "handles functions with arguments" do
    successfully "rails generate fx:function adder"
    write_function_definition "adder_v01", <<-EOS
      CREATE FUNCTION adder(x int, y int)
      RETURNS int AS $$
      BEGIN
          RETURN $1 + $2;
      END;
      $$ LANGUAGE plpgsql;
    EOS
    successfully "rake db:migrate"

    result = execute("SELECT * FROM adder(1, 2) AS result")
    result["result"] = result["result"].to_i
    expect(result).to eq("result" => 3)

    successfully "rails destroy fx:function adder"
    successfully "rake db:migrate"
  end

  it "replaces functions with dependencies" do
    successfully "rails generate model person name:string case_name:string"
    successfully "rails generate fx:function case_people_name"
    write_function_definition "case_people_name_v01", <<-EOS
      CREATE OR REPLACE FUNCTION case_people_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.case_name = UPPER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    EOS

    successfully "rails generate fx:trigger case_people_name table_name:people"
    write_trigger_definition "case_people_name_v01", <<-EOS
      CREATE TRIGGER case_people_name
          BEFORE INSERT ON people
          FOR EACH ROW
          EXECUTE PROCEDURE case_people_name();
    EOS
    successfully "rake db:migrate"

    execute <<-EOS
      INSERT INTO people
      (name, created_at, updated_at)
      VALUES
      ('Bob', NOW(), NOW());
    EOS
    result = execute("SELECT case_name FROM people WHERE name = 'Bob';")
    expect(result).to eq("case_name" => "BOB")

    successfully "rails generate fx:function case_people_name --replace"
    write_function_definition "case_people_name_v02", <<-EOS
      CREATE OR REPLACE FUNCTION case_people_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.case_name = LOWER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    EOS
    successfully "rake db:migrate"

    execute <<-EOS
      INSERT INTO people
      (name, created_at, updated_at)
      VALUES
      ('Alice', NOW(), NOW());
    EOS
    result = execute("SELECT case_name FROM people WHERE name = 'Alice';")
    expect(result).to eq("case_name" => "alice")
  end
end
