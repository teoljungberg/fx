require "spec_helper"

# rubocop:disable Metrics/BlockLength

RSpec.describe Fx::SchemaDumper::Function, :db do
  it "dumps a create_function for a function in the database" do
    sql_definition = <<-EOS
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

    ActiveRecord::SchemaDumper.dump(connection, stream)

    expect(output).to(
      match(/table "my_table".*function :my_function.*RETURN 'test';/m)
    )
  end

  it "dumps a create_function for a function in the database" do
    Fx.configuration.dump_functions_at_beginning_of_schema = true
    sql_definition = <<-EOS
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

    ActiveRecord::SchemaDumper.dump(connection, stream)

    expect(output).to(
      match(/function :my_function.*RETURN 'test';.*table "my_table"/m)
    )
  ensure
    Fx.configuration.dump_functions_at_beginning_of_schema = false
  end

  context "when check_function_bodies is false" do
    it "outputs `SET LOCAL check_function_bodies TO false`" do
      Fx.configuration.check_function_bodies = false

      sql_definition = <<-EOS
          CREATE OR REPLACE FUNCTION my_function()
          RETURNS text AS $$
          BEGIN
              RETURN 'test';
          END;
          $$ LANGUAGE plpgsql;
      EOS
      connection.create_function :my_function, sql_definition: sql_definition
      stream = StringIO.new
      output = stream.string

      ActiveRecord::SchemaDumper.dump(connection, stream)
      expect(output.gsub(/^ +/, '')).to match(
        /BEGIN;\n*SET LOCAL check_function_bodies TO false;\n*CREATE OR REPLACE FUNCTION/
      )

      expect(output.gsub(/^ +/, '')).to match(/\$function\$;\n+.*COMMIT;\n+SQL/)
    end
  ensure
    Fx.configuration.check_function_bodies = true
  end

  context "when check_function_bodies is true" do
    it "outputs `SET LOCAL check_function_bodies TO true`" do
      Fx.configuration.check_function_bodies = true

      sql_definition = <<-EOS
          CREATE OR REPLACE FUNCTION my_function()
          RETURNS text AS $$
          BEGIN
              RETURN 'test';
          END;
          $$ LANGUAGE plpgsql;
      EOS
      connection.create_function :my_function, sql_definition: sql_definition
      stream = StringIO.new
      output = stream.string

      ActiveRecord::SchemaDumper.dump(connection, stream)

      expect(output.gsub(/^ +/, '')).to match(
        /BEGIN;\n*SET LOCAL check_function_bodies TO true;\n*CREATE OR REPLACE FUNCTION/
      )

      expect(output.gsub(/^ +/, '')).to match(/\$function\$;\n+.*COMMIT;\n+SQL/)
    end
  ensure
    Fx.configuration.check_function_bodies = true
  end

  context "when check_function_bodies is nil" do
    it "does not output `SET LOCAL check_function_bodies`" do
      Fx.configuration.check_function_bodies = nil

      sql_definition = <<-EOS
          CREATE OR REPLACE FUNCTION my_function()
          RETURNS text AS $$
          BEGIN
              RETURN 'test';
          END;
          $$ LANGUAGE plpgsql;
      EOS
      connection.create_function :my_function, sql_definition: sql_definition
      stream = StringIO.new
      output = stream.string

      ActiveRecord::SchemaDumper.dump(connection, stream)

      expect(output).not_to match(
        /SET LOCAL check_function_bodies/
      )

      expect(output).not_to match(/COMMIT;/)
    end
  ensure
    Fx.configuration.check_function_bodies = true
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
    expect(output).to include "create_function :test, sql_definition: <<-'SQL'"
    expect(output).to include "RETURN 'test';"
    expect(output).not_to include "aggregate_test"
  end
end

# rubocop:enable Metrics/BlockLength
