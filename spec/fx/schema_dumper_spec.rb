require "spec_helper"

RSpec.describe Fx::SchemaDumper, :db do
  it "dumps a create_function for a function in the database" do
    sql_definition = <<~SQL
      CREATE OR REPLACE FUNCTION my_function()
      RETURNS text AS $$
      BEGIN
          RETURN 'test';
      END;
      $$ LANGUAGE plpgsql;
    SQL
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
    sql_definition = <<~SQL
      CREATE OR REPLACE FUNCTION my_function()
      RETURNS text AS $$
      BEGIN
          RETURN 'test';
      END;
      $$ LANGUAGE plpgsql;
    SQL
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
    sql_definition = <<~SQL
      CREATE OR REPLACE FUNCTION test(text, text)
      RETURNS text AS $$
      BEGIN
          RETURN 'test';
      END;
      $$ LANGUAGE plpgsql;
    SQL

    aggregate_sql_definition = <<~SQL
      CREATE AGGREGATE aggregate_test(text)
      (
          sfunc = test,
          stype = text
      );
    SQL

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
    connection.execute <<~SQL
      CREATE TABLE users (
          id int PRIMARY KEY,
          name varchar(256),
          upper_name varchar(256)
      );
    SQL
    Fx.database.create_function <<~SQL
      CREATE OR REPLACE FUNCTION uppercase_users_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.upper_name = UPPER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    sql_definition = <<~SQL
      CREATE TRIGGER uppercase_users_name
          BEFORE INSERT ON users
          FOR EACH ROW
          EXECUTE FUNCTION uppercase_users_name();
    SQL
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

  it "dumps functions and triggers for multiple schemas" do
    connection.schema_search_path = "public,test_schema"
    connection.create_table :my_table
    connection.create_function :test1, sql_definition: <<~SQL
      CREATE OR REPLACE FUNCTION test_public_func()
      RETURNS TRIGGER AS $$
      BEGIN
        RETURN 1;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    connection.create_trigger :test1_trigger, sql_definition: <<~SQL
      CREATE TRIGGER test_public_trigger
      BEFORE INSERT ON my_table
      FOR EACH ROW
      EXECUTE FUNCTION test_public_func();
    SQL
    connection.execute("CREATE SCHEMA test_schema;")
    connection.create_table "test_schema.my_table2"
    connection.execute <<~SQL
      CREATE OR REPLACE FUNCTION test_schema.test_schema_func()
      RETURNS TRIGGER AS $$
      BEGIN
        RETURN 'test_schema';
      END;
      $$ LANGUAGE plpgsql;
    SQL
    connection.execute <<~SQL
      CREATE TRIGGER test_schema_trigger
      BEFORE INSERT ON test_schema.my_table2
      FOR EACH ROW
      EXECUTE FUNCTION test_schema.test_schema_func();
    SQL
    stream = StringIO.new
    output = stream.string

    dump(connection: connection, stream: stream)

    expect(output.scan("create_function :test_public_func").size).to eq(1)
    expect(output.scan("create_trigger :test_public_trigger").size).to eq(1)
    expect(output.scan("create_function :test_schema_func").size).to eq(1)
    expect(output.scan("create_trigger :test_schema_trigger").size).to eq(1)
  ensure
    connection.schema_search_path = "public"
  end

  it "puts a blank line before each function and trigger" do
    connection.create_table :users do |t|
      t.string :name
      t.string :upper_name
      t.string :down_name
    end
    Fx.database.create_function <<~SQL
      CREATE OR REPLACE FUNCTION uppercase_users_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.upper_name = UPPER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    sql_definition = <<~SQL
      CREATE TRIGGER uppercase_users_name
          BEFORE INSERT ON users
          FOR EACH ROW
          EXECUTE FUNCTION uppercase_users_name();
    SQL
    connection.create_trigger(
      :uppercase_users_name,
      sql_definition: sql_definition
    )
    Fx.database.create_function <<~SQL
      CREATE OR REPLACE FUNCTION downcase_users_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.down_name = LOWER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    sql_definition = <<~SQL
      CREATE TRIGGER downcase_users_name
          BEFORE INSERT ON users
          FOR EACH ROW
          EXECUTE FUNCTION downcase_users_name();
    SQL
    connection.create_trigger(
      :downcase_users_name,
      sql_definition: sql_definition
    )
    stream = StringIO.new
    output = stream.string

    dump(connection: connection, stream: stream)

    pattern = /(end|SQL)\n\n  (create_function|create_trigger)/
    # a blank line between:
    # - the table and the uppercase_users_name function,
    # - the uppercase_users_name function and the downcase_users_name function,
    # - the downcase_users_name function and the uppercase_users_name trigger,
    # - the uppercase_users_name trigger and the downcase_users_name trigger,
    expect(output.scan(pattern).size).to eq(4)
  end

  it "does not add blank lines when there are no functions or triggers" do
    connection.create_table :users do |t|
      t.string :name
    end
    stream = StringIO.new
    output = stream.string

    dump(connection: connection, stream: stream)

    expect(output).not_to match(/create_function/)
    expect(output).not_to match(/create_trigger/)
    expect(output).not_to match(/end\n\n\nend/)
  end

  def dump(connection:, stream:)
    if Rails.version >= "7.2"
      ActiveRecord::SchemaDumper.dump(connection.pool, stream)
    else
      ActiveRecord::SchemaDumper.dump(connection, stream)
    end
  end
end
