require "spec_helper"

describe Fx::SchemaDumper::View, :db do
  it "dumps a create_view for a view in the database" do
    connection.execute <<-EOS
      CREATE TABLE users (
          id int PRIMARY KEY,
          name varchar(256),
          upper_name varchar(256),
          active boolean
      );
    EOS
    sql_definition = <<-EOS
      CREATE VIEW active_users AS
        SELECT * FROM users WHERE active = true;
    EOS
    connection.create_view :my_view, sql_definition: sql_definition
    stream = StringIO.new
    output = stream.string

    ActiveRecord::SchemaDumper.dump(connection, stream)

    expect(output).to include "create_view :active_users"
    expect(output).to include "sql_definition: <<-SQL"
    expect(output).to include "SELECT users.id"
    expect(output).to include "users.upper_name"
    expect(output).to include "users.active"
    expect(output).to include "FROM users"
    expect(output).to include "WHERE (users.active = true)"
  end

  it "dumps a create_view for a materiaalized view in the database" do
    connection.execute <<-EOS
      CREATE TABLE users (
          id int PRIMARY KEY,
          name varchar(256),
          upper_name varchar(256),
          active boolean
      );
    EOS
    sql_definition = <<-EOS
      CREATE MATERIALIZED VIEW active_users AS
        SELECT * FROM users WHERE active = true;
    EOS
    connection.create_view :my_view, sql_definition: sql_definition
    stream = StringIO.new
    output = stream.string

    ActiveRecord::SchemaDumper.dump(connection, stream)

    expect(output).to include "create_view :active_users"
    expect(output).to include "sql_definition: <<-SQL"
    expect(output).to include "SELECT users.id"
    expect(output).to include "users.upper_name"
    expect(output).to include "users.active"
    expect(output).to include "FROM users"
    expect(output).to include "WHERE (users.active = true)"
  end
end
