require "spec_helper"

module Fx::Adapters
  describe Postgres, :db do
    describe ".create_function" do
      it "successfully creates a function" do
        Postgres.create_function(
          <<~EOS
            CREATE OR REPLACE FUNCTION test() RETURNS text AS $$
            BEGIN
                RETURN 'test';
            END;
            $$ LANGUAGE plpgsql;
          EOS
        )

        expect(Postgres.functions.map(&:name)).to include("test")
      end
    end

    describe ".drop_function" do
      it "successfully drops a function" do
        Postgres.create_function(
          <<~EOS
            CREATE OR REPLACE FUNCTION test() RETURNS text AS $$
            BEGIN
                RETURN 'test';
            END;
            $$ LANGUAGE plpgsql;
          EOS
        )

        Postgres.drop_function(:test)

        expect(Postgres.functions.map(&:name)).not_to include("test")
      end
    end

    describe ".functions" do
      it "finds functions and builds Fx::Function objects" do
        Postgres.create_function(
          <<~EOS
            CREATE OR REPLACE FUNCTION test() RETURNS text AS $$
            BEGIN
                RETURN 'test';
            END;
            $$ LANGUAGE plpgsql;
          EOS
        )

        expect(Postgres.functions).to eq([
          Fx::Function.new(
            "name" => "test",
            "definition" => <<~EOS
              CREATE OR REPLACE FUNCTION public.test()
               RETURNS text
               LANGUAGE plpgsql
              AS $function$
              BEGIN
                  RETURN 'test';
              END;
              $function$
            EOS
          ),
        ])
      end
    end
  end
end
