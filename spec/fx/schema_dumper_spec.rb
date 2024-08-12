require "spec_helper"

RSpec.describe Fx::SchemaDumper, :db do
  it "dumps a create_function for a function in the database" do
    sql_definition = <<~EOS
      CREATE OR REPLACE FUNCTION my_function()
      RETURNS text AS $$
      BEGIN
          RETURN 'test';
      END;
      $$ LANGUAGE plpgsql;
    EOS
    connection.create_function :my_function, sql_definition: sql_definition
    connection.create_table :my_table
    stream = StringIO.new
    output = stream.string

    dump(connection: connection, stream: stream)

    expect(output).to match(
      /table "my_table".*function :my_function.*RETURN 'test';/m
    )
  end

  it "dumps a create_function for a function in the database" do
    Fx.configuration.dump_functions_at_beginning_of_schema = true
    sql_definition = <<~EOS
      CREATE OR REPLACE FUNCTION my_function()
      RETURNS text AS $$
      BEGIN
          RETURN 'test';
      END;
      $$ LANGUAGE plpgsql;
    EOS
    connection.create_function :my_function, sql_definition: sql_definition
    connection.create_table :my_table
    stream = StringIO.new
    output = stream.string

    dump(connection: connection, stream: stream)

    expect(output).to(
      match(/function :my_function.*RETURN 'test';.*table "my_table"/m)
    )

    Fx.configuration.dump_functions_at_beginning_of_schema = false
  end

  it "does not dump a create_function for aggregates in the database" do
    sql_definition = <<~EOS
      CREATE OR REPLACE FUNCTION test(text, text)
      RETURNS text AS $$
      BEGIN
          RETURN 'test';
      END;
      $$ LANGUAGE plpgsql;
    EOS

    aggregate_sql_definition = <<~EOS
      CREATE AGGREGATE aggregate_test(text)
      (
          sfunc = test,
          stype = text
      );
    EOS

    connection.create_function :test, sql_definition: sql_definition
    connection.execute aggregate_sql_definition
    stream = StringIO.new

    dump(connection: connection, stream: stream)

    output = stream.string
    expect(output).to include("create_function :test, sql_definition: <<-'SQL'")
    expect(output).to include("RETURN 'test';")
    expect(output).not_to include("aggregate_test")
  end

  it "dumps a create_trigger for a trigger in the database" do
    connection.execute <<~EOS
      CREATE TABLE users (
          id int PRIMARY KEY,
          name varchar(256),
          upper_name varchar(256)
      );
    EOS
    Fx.database.create_function <<~EOS
      CREATE OR REPLACE FUNCTION uppercase_users_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.upper_name = UPPER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    EOS
    sql_definition = <<~EOS
      CREATE TRIGGER uppercase_users_name
          BEFORE INSERT ON users
          FOR EACH ROW
          EXECUTE FUNCTION uppercase_users_name();
    EOS
    connection.create_trigger(
      :uppercase_users_name,
      sql_definition: sql_definition
    )
    stream = StringIO.new

    dump(connection: connection, stream: stream)

    output = stream.string
    expect(output).to include("create_trigger :uppercase_users_name")
    expect(output).to include("sql_definition: <<-SQL")
    expect(output).to include("EXECUTE FUNCTION uppercase_users_name()")
  end

  def dump(connection:, stream:)
    if Rails.version >= "7.2"
      ActiveRecord::SchemaDumper.dump(connection.pool, stream)
    else
      ActiveRecord::SchemaDumper.dump(connection, stream)
    end
  end
end
