require "spec_helper"

describe Fx::SchemaDumper::Function, :db do
  it "dumps a create_function for a function in the database" do
    sql_definition = <<-EOS
      CREATE OR REPLACE FUNCTION test()
      RETURNS text AS $$
      BEGIN
          RETURN 'test';
      END;
      $$ LANGUAGE plpgsql;
    EOS
    connection.create_function :test, sql_definition: sql_definition
    stream = StringIO.new

    ActiveRecord::SchemaDumper.dump(connection, stream)

    output = stream.string
    expect(output).to include "create_function :test, sql_definition: <<-SQL"
    expect(output).to include "RETURN 'test';"
  end

  it "does not dump a create_function for aggregates in the database" do
    sql_definition = <<-EOS
      CREATE OR REPLACE FUNCTION test(text, text)
      RETURNS text AS $$
      BEGIN
          RETURN 'test';
      END;
      $$ LANGUAGE plpgsql;
    EOS

    aggregate_sql_definition = <<-EOS
      CREATE AGGREGATE aggregate_test(text)
      (
          sfunc = test,
          stype = text
      );
    EOS

    connection.create_function :test, sql_definition: sql_definition
    connection.execute aggregate_sql_definition
    stream = StringIO.new

    ActiveRecord::SchemaDumper.dump(connection, stream)

    output = stream.string
    expect(output).to include "create_function :test, sql_definition: <<-SQL"
    expect(output).to include "RETURN 'test';"
    expect(output).not_to include "aggregate_test"
  end
end
