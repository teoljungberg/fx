require "acceptance_helper"

describe "User manages views" do
  it "handles simple views" do
    successfully "rails generate model employee name:string active:boolean"
    successfully "rails generate fx:view active_employees"
    write_view_definition "active_employees_v01", <<-EOS
      CREATE VIEW active_employees AS
          SELECT * FROM employees WHERE active = true;
    EOS
    successfully "rake db:migrate"

    execute <<-EOS
      INSERT INTO employees
      (name, created_at, updated_at, active)
      VALUES
      ('Bob', NOW(), NOW(), true),
      ('John', NOW(), NOW(), false);
    EOS
    result = execute("SELECT name FROM active_employees;")
    expect(result).to eq("name" => "Bob")
  end
end
