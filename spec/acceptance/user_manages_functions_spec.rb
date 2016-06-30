require "acceptance_helper"

describe "User manages functions" do
  it "handles simple functions" do
    successfully "rails generate fx:function test"
    write_definition "test_v01", <<~EOS
      CREATE OR REPLACE FUNCTION test() RETURNS text AS $$
      BEGIN
          RETURN 'test';
      END;
      $$ LANGUAGE plpgsql;
    EOS
    successfully "rake db:migrate"

    result = execute("SELECT * FROM test() AS result")
    expect(result).to eq("result" => "test")

    successfully "rails generate fx:function test"
    verify_identical_function_definitions "test_v01", "test_v02"
    write_definition "test_v02", <<~EOS
      CREATE OR REPLACE FUNCTION test() RETURNS text AS $$
      BEGIN
          RETURN 'testest';
      END;
      $$ LANGUAGE plpgsql;
    EOS
    successfully "rake db:migrate"

    result = execute("SELECT * FROM test() AS result")
    expect(result).to eq("result" => "testest")
  end

  def successfully(command)
    `RAILS_ENV=test #{command}`
    expect($?.exitstatus).to eq(0), "'#{command}' was unsuccessful"
  end

  def write_definition(file, contents)
    File.open("db/functions/#{file}.sql", File::WRONLY) do |definition|
      definition.truncate(0)
      definition.write(contents)
    end
  end

  def verify_identical_function_definitions(def_a, def_b)
    successfully "cmp db/functions/#{def_a}.sql db/functions/#{def_b}.sql"
  end

  def execute(command)
    ActiveRecord::Base.connection.execute(command).first
  end
end
