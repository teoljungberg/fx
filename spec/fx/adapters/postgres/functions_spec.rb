require "spec_helper"

RSpec.describe Fx::Adapters::Postgres::Functions, :db do
  describe ".all" do
    it "returns `Function` objects" do
      connection = ActiveRecord::Base.connection
      connection.execute <<-EOS.strip_heredoc
        CREATE OR REPLACE FUNCTION test()
        RETURNS text AS $$
        BEGIN
            RETURN 'test';
        END;
        $$ LANGUAGE plpgsql;
      EOS

      connection.execute <<-EOS.strip_heredoc
        CREATE OR REPLACE FUNCTION foo()
        RETURNS text AS $$
        BEGIN
            RETURN 'foo';
        END;
        $$ LANGUAGE plpgsql;
      EOS

      functions = Fx::Adapters::Postgres::Functions.new(connection).all

      expect(functions).to match(
        [
          an_object_having_attributes(name: "foo", definition: a_string_matching(/CREATE OR REPLACE FUNCTION public.foo()/)),
          an_object_having_attributes(name: "test", definition: a_string_matching(/CREATE OR REPLACE FUNCTION public.test()/))
        ]
      )
    end
  end
end
