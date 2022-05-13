require "spec_helper"

describe Fx::SchemaDumper::Trigger, :db do
  it "dumps a create_trigger for a trigger in the database" do
    connection.execute <<-EOS
      CREATE TABLE users (
          id int PRIMARY KEY,
          name varchar(256),
          upper_name varchar(256)
      );
    EOS
    Fx.database.create_function <<-EOS
      CREATE OR REPLACE FUNCTION uppercase_users_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.upper_name = UPPER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    EOS
    sql_definition = <<-EOS
      CREATE TRIGGER uppercase_users_name
          BEFORE INSERT ON users
          FOR EACH ROW
          EXECUTE PROCEDURE uppercase_users_name();
    EOS
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

  it "dumps only included triggers" do
    begin
      Fx.configuration.exclude_trigger_from_schema_condition = lambda do |trigger|
        trigger.name == "lowercase_users_name"
      end

      connection.execute <<-EOS
      CREATE TABLE users (
          id int PRIMARY KEY,
          name varchar(256),
          upper_name varchar(256),
          lower_name varchar(256)
      );
      EOS

      Fx.database.create_function <<-EOS
      CREATE OR REPLACE FUNCTION uppercase_users_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.upper_name = UPPER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
      EOS

      Fx.database.create_function <<-EOS
      CREATE OR REPLACE FUNCTION lowercase_users_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.lower_name = LOWER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
      EOS

      sql_definition_allowed = <<-EOS
      CREATE TRIGGER uppercase_users_name
          BEFORE INSERT ON users
          FOR EACH ROW
          EXECUTE PROCEDURE uppercase_users_name();
      EOS

      sql_definition_disallowed = <<-EOS
      CREATE TRIGGER lowercase_users_name
          BEFORE INSERT ON users
          FOR EACH ROW
          EXECUTE PROCEDURE lowercase_users_name();
      EOS

      connection.create_trigger(
        :uppercase_users_name,
        sql_definition: sql_definition_allowed,
      )

      connection.create_trigger(
        :lowercase_users_name,
        sql_definition: sql_definition_disallowed,
      )

      stream = StringIO.new

      ActiveRecord::SchemaDumper.dump(connection, stream)

      output = stream.string
      expect(output).to include "create_trigger :uppercase_users_name"
      expect(output).not_to include "create_trigger :lowercase_users_name"
      expect(output).to include "sql_definition: <<-SQL"
      expect(output).to include "EXECUTE PROCEDURE uppercase_users_name()"
    ensure
      Fx.configuration.exclude_trigger_from_schema_condition = lambda { |trigger| false }
    end
  end
end
