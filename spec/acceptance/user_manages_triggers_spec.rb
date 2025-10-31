require "acceptance_helper"

RSpec.describe "User manages triggers" do
  it "handles simple triggers" do
    successfully "rails generate model user name:string upper_name:string"
    successfully "rails generate fx:function uppercase_users_name"
    write_function_definition "uppercase_users_name_v01", <<~SQL
      CREATE OR REPLACE FUNCTION uppercase_users_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.upper_name = UPPER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    successfully "rails generate fx:trigger uppercase_users_name table_name:users"
    write_trigger_definition "uppercase_users_name_v01", <<~SQL
      CREATE TRIGGER uppercase_users_name
          BEFORE INSERT ON users
          FOR EACH ROW
          EXECUTE FUNCTION uppercase_users_name();
    SQL
    successfully "rake db:migrate"

    execute <<~SQL
      INSERT INTO users
      (name, created_at, updated_at)
      VALUES
      ('Bob', NOW(), NOW());
    SQL
    result = execute("SELECT upper_name FROM users WHERE name = 'Bob';")
    expect(result).to eq("upper_name" => "BOB")

    successfully "rails generate fx:trigger uppercase_users_name table_name:users"
    write_trigger_definition "uppercase_users_name_v02", <<~SQL
      CREATE TRIGGER uppercase_users_name
          BEFORE UPDATE ON users
          FOR EACH ROW
          EXECUTE FUNCTION uppercase_users_name();
    SQL
    successfully "rake db:migrate"
    execute <<~SQL
      UPDATE users
      SET name = 'Alice'
      WHERE id = 1;
    SQL

    result = execute("SELECT upper_name FROM users WHERE name = 'Alice';")
    expect(result).to eq("upper_name" => "ALICE")
  end
end
