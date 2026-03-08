require "spec_helper"

RSpec.describe Fx::SchemaDumper, :db do
  it "dumps a create_function for a function in the database" do
    sql_definition = <<~SQL
      CREATE OR REPLACE FUNCTION value()
      RETURNS text AS $$
      BEGIN
          RETURN 'value';
      END;
      $$ LANGUAGE plpgsql;
    SQL
    connection.create_function :value, sql_definition: sql_definition
    connection.create_table :my_table
    stream = StringIO.new
    output = stream.string

    dump(connection: connection, stream: stream)

    expect(output).to match(
      /table "my_table".*function :value.*RETURN 'value';/m
    )
  end

  it "dumps a create_function for a function in the database" do
    Fx.configuration.dump_functions_at_beginning_of_schema = true
    sql_definition = <<~SQL
      CREATE OR REPLACE FUNCTION value()
      RETURNS text AS $$
      BEGIN
          RETURN 'value';
      END;
      $$ LANGUAGE plpgsql;
    SQL
    connection.create_function :value, sql_definition: sql_definition
    connection.create_table :my_table
    stream = StringIO.new
    output = stream.string

    dump(connection: connection, stream: stream)

    expect(output).to(
      match(/function :value.*RETURN 'value';.*table "my_table"/m)
    )

    Fx.configuration.dump_functions_at_beginning_of_schema = false
  end

  it "does not dump a create_function for aggregates in the database" do
    sql_definition = <<~SQL
      CREATE OR REPLACE FUNCTION add(text, text)
      RETURNS text AS $$
      BEGIN
          RETURN 'value';
      END;
      $$ LANGUAGE plpgsql;
    SQL

    aggregate_sql_definition = <<~SQL
      CREATE AGGREGATE aggregate_add(text)
      (
          sfunc = add,
          stype = text
      );
    SQL

    connection.create_function :add, sql_definition: sql_definition
    connection.execute aggregate_sql_definition
    stream = StringIO.new

    dump(connection: connection, stream: stream)

    output = stream.string
    expect(output).to include("create_function :add, sql_definition: <<-'SQL'")
    expect(output).to include("RETURN 'value';")
    expect(output).not_to include("aggregate_add")
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
      CREATE OR REPLACE FUNCTION set_upper_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.upper_name = UPPER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    sql_definition = <<~SQL
      CREATE TRIGGER set_upper_name
          BEFORE INSERT ON users
          FOR EACH ROW
          EXECUTE FUNCTION set_upper_name();
    SQL
    connection.create_trigger(
      :set_upper_name,
      sql_definition: sql_definition
    )
    stream = StringIO.new

    dump(connection: connection, stream: stream)

    output = stream.string
    expect(output).to include("create_trigger :set_upper_name")
    expect(output).to include("sql_definition: <<-SQL")
    expect(output).to include("EXECUTE FUNCTION set_upper_name()")
  end

  it "dumps functions and triggers for multiple schemas" do
    connection.schema_search_path = "public,test_schema"
    connection.create_table :my_table
    connection.create_function :add, sql_definition: <<~SQL
      CREATE OR REPLACE FUNCTION add()
      RETURNS TRIGGER AS $$
      BEGIN
        RETURN 1;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    connection.create_trigger :set_upper_name, sql_definition: <<~SQL
      CREATE TRIGGER set_upper_name
      BEFORE INSERT ON my_table
      FOR EACH ROW
      EXECUTE FUNCTION add();
    SQL
    connection.execute("CREATE SCHEMA test_schema;")
    connection.create_table "test_schema.my_table2"
    connection.execute <<~SQL
      CREATE OR REPLACE FUNCTION test_schema.multiply()
      RETURNS TRIGGER AS $$
      BEGIN
        RETURN 'test_schema';
      END;
      $$ LANGUAGE plpgsql;
    SQL
    connection.execute <<~SQL
      CREATE TRIGGER set_lower_name
      BEFORE INSERT ON test_schema.my_table2
      FOR EACH ROW
      EXECUTE FUNCTION test_schema.multiply();
    SQL
    stream = StringIO.new
    output = stream.string

    dump(connection: connection, stream: stream)

    expect(output.scan("create_function :add").size).to eq(1)
    expect(output.scan("create_trigger :set_upper_name").size).to eq(1)
    expect(output.scan("create_function :multiply").size).to eq(1)
    expect(output.scan("create_trigger :set_lower_name").size).to eq(1)
  ensure
    connection.schema_search_path = "public"
  end

  it "puts a blank line before each function and trigger" do
    connection.create_table :users do |t|
      t.string :name
      t.string :upper_name
      t.string :lower_name
    end
    Fx.database.create_function <<~SQL
      CREATE OR REPLACE FUNCTION set_upper_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.upper_name = UPPER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    sql_definition = <<~SQL
      CREATE TRIGGER set_upper_name
          BEFORE INSERT ON users
          FOR EACH ROW
          EXECUTE FUNCTION set_upper_name();
    SQL
    connection.create_trigger(
      :set_upper_name,
      sql_definition: sql_definition
    )
    Fx.database.create_function <<~SQL
      CREATE OR REPLACE FUNCTION set_lower_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.lower_name = LOWER(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    sql_definition = <<~SQL
      CREATE TRIGGER set_lower_name
          BEFORE INSERT ON users
          FOR EACH ROW
          EXECUTE FUNCTION set_lower_name();
    SQL
    connection.create_trigger(
      :set_lower_name,
      sql_definition: sql_definition
    )
    stream = StringIO.new
    output = stream.string

    dump(connection: connection, stream: stream)

    pattern = /(end|SQL)\n\n  (create_function|create_trigger)/
    # a blank line between:
    # - the table and the set_lower_name function,
    # - the set_lower_name function and the set_upper_name function,
    # - the set_upper_name function and the set_lower_name trigger,
    # - the set_lower_name trigger and the set_upper_name trigger,
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
