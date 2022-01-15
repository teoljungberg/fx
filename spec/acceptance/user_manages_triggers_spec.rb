require "acceptance_helper"

describe "User manages triggers" do
  let(:table_name_prefix) { TABLE_NAME_PREFIX }
  let(:table_name_suffix) { TABLE_NAME_SUFFIX }

  def full_table_name(table_name)
    "#{table_name_prefix}#{table_name}#{table_name_suffix}"
  end

  it "handles simple triggers" do
    successfully "rails generate model user name:string upper_name:string"
    successfully "rails generate fx:function uppercase_users_name"
    write_function_definition "uppercase_users_name_v01", <<-EOS
      CREATE OR REPLACE FUNCTION uppercase_users_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.upper_name = UPPER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    EOS
    successfully "rails generate fx:trigger uppercase_users_name table_name:users"
    write_trigger_definition "uppercase_users_name_v01", <<-EOS
      CREATE TRIGGER uppercase_users_name
          BEFORE INSERT ON "#{full_table_name('users')}"
          FOR EACH ROW
          EXECUTE PROCEDURE uppercase_users_name();
    EOS
    successfully "rake db:migrate"

    execute <<-EOS
      INSERT INTO "#{full_table_name('users')}"
      (name, created_at, updated_at)
      VALUES
      ('Bob', NOW(), NOW());
    EOS
    result = execute("SELECT upper_name FROM \"#{full_table_name('users')}\" WHERE name = 'Bob';")
    expect(result).to eq("upper_name" => "BOB")

    successfully "rails generate fx:trigger uppercase_users_name table_name:users"
    write_trigger_definition "uppercase_users_name_v02", <<-EOS
      CREATE TRIGGER uppercase_users_name
          BEFORE UPDATE ON "#{full_table_name('users')}"
          FOR EACH ROW
          EXECUTE PROCEDURE uppercase_users_name();
    EOS
    successfully "rake db:migrate"
    execute <<-EOS
      UPDATE "#{full_table_name('users')}"
      SET name = 'Alice'
      WHERE id = 1;
    EOS

    result = execute("SELECT upper_name FROM \"#{full_table_name('users')}\" WHERE name = 'Alice';")
    expect(result).to eq("upper_name" => "ALICE")
  end
end
