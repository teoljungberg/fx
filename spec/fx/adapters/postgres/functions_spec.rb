require "spec_helper"

RSpec.describe Fx::Adapters::Postgres::Functions, :db do
  def create_function_sql(name)
    <<-FX.strip_heredoc
      CREATE OR REPLACE FUNCTION #{name}()
       RETURNS text
       LANGUAGE plpgsql
      AS $function$
      BEGIN
          RETURN 'test';
      END;
      $function$
    FX
  end

  describe ".all" do
    it "returns `Function` objects in all schemas" do
      connection = ActiveRecord::Base.connection
      connection.execute "CREATE SCHEMA test_schema"
      connection.execute create_function_sql("public.test")
      connection.execute create_function_sql("test_schema.test")
      functions = Fx::Adapters::Postgres::Functions.new(connection).all

      expect(functions.size).to eq 2
      expect(functions[0].name).to eq "test"
      expect(functions[0].definition).to eq create_function_sql("test")
      expect(functions[1].name).to eq "test_schema.test"
      expect(functions[1].definition).to eq create_function_sql("test_schema.test")
    end
  end

  context "when 'public' is not the default schema" do
    it "returns `Function` objects with schema-aware names and definitions" do
      connection = ActiveRecord::Base.connection
      search_path_was = connection.execute("SHOW search_path")[0]["search_path"]

      connection.execute "SET search_path TO test_schema"
      connection.execute "CREATE SCHEMA test_schema"
      connection.execute create_function_sql("public.test")
      connection.execute create_function_sql("test_schema.test")
      functions = Fx::Adapters::Postgres::Functions.new(connection).all

      expect(functions.size).to eq 2
      expect(functions[0].name).to eq "public.test"
      expect(functions[0].definition).to eq create_function_sql("public.test")
      expect(functions[1].name).to eq "test"
      expect(functions[1].definition).to eq create_function_sql("test")
    ensure
      connection.execute "SET search_path TO #{search_path_was}"
    end
  end
end
