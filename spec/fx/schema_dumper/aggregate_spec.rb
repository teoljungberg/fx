require "spec_helper"

describe Fx::SchemaDumper::Aggregate, :db do
  it "dumps a create_aggregate for an aggregate in the database" do
    sql_definition = <<-EOS
      CREATE AGGREGATE test(anyelement)(
          SFUNC = array_append,
          STYPE = anyarray,
          INITCOND = '{}'
      );
    EOS
    connection.create_aggregate :test, sql_definition: sql_definition
    stream = StringIO.new

    ActiveRecord::SchemaDumper.dump(connection, stream)

    output = stream.string
    expect(output).to include <<-SCHEMA
  create_aggregate :test, sql_definition: <<-SQL
      CREATE AGGREGATE test(anyelement)(
          SFUNC = array_append,
          STYPE = anyarray,
          INITCOND = '{}'
      );
  SQL
    SCHEMA
  end
end
