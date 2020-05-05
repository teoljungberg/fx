require "spec_helper"

describe Fx::SchemaDumper::Trigger, :db do
  it "dumps a create_trigger for a trigger in the database" do
    connection.execute <<-SQL
      CREATE TABLE users (
          id int PRIMARY KEY,
          name varchar(256),
          upper_name varchar(256)
      );
    SQL
    Fx.database.create_function <<-SQL
      CREATE OR REPLACE FUNCTION uppercase_users_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.upper_name = UPPER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    sql_definition = <<-SQL
      CREATE TRIGGER uppercase_users_name
          BEFORE INSERT ON users
          FOR EACH ROW
          EXECUTE PROCEDURE uppercase_users_name();
    SQL
    connection.create_trigger(
      :uppercase_users_name,
      sql_definition: sql_definition,
    )
    stream = StringIO.new

    ActiveRecord::SchemaDumper.dump(connection, stream)

    output = stream.string
    expect(output).to include "create_trigger :uppercase_users_name"
    expect(output).to include "sql_definition: <<-SQL"
    expect(output).to include "EXECUTE PROCEDURE uppercase_users_name()"
  end
end
