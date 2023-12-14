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

      functions = Fx::Adapters::Postgres::Functions.new(connection).all

      first = functions.first
      expect(functions.size).to eq 1
      expect(first.name).to eq "test"
      expect(first.definition).to eq <<-EOS.strip_heredoc
        CREATE OR REPLACE FUNCTION public.test()
         RETURNS text
         LANGUAGE plpgsql
        AS $function$
        BEGIN
            RETURN 'test';
        END;
        $function$
      EOS
    end

    context "when functions are in a different schema" do
      it "does not return the `Function` objects" do
        connection = ActiveRecord::Base.connection
        connection.execute <<-EOS.strip_heredoc
          CREATE SCHEMA test_schema;
          CREATE OR REPLACE FUNCTION test_schema.test()
          RETURNS text AS $$
          BEGIN
              RETURN 'test';
          END;
          $$ LANGUAGE plpgsql;
        EOS

        functions = Fx::Adapters::Postgres::Functions.new(connection).all

        expect(functions).to be_empty
      end

      context "when the other schema is in the search path" do
        it "returns the `Function` objects" do
          connection = ActiveRecord::Base.connection
          connection.execute <<-EOS.strip_heredoc
            CREATE SCHEMA test_schema;
            SET search_path TO public,test_schema;
            CREATE OR REPLACE FUNCTION test_schema.test()
            RETURNS text AS $$
            BEGIN
                RETURN 'test';
            END;
            $$ LANGUAGE plpgsql;
          EOS

          functions = Fx::Adapters::Postgres::Functions.new(connection).all

          first = functions.first
          expect(functions.size).to eq 1
          expect(first.name).to eq "test"
          expect(first.definition).to eq <<-EOS.strip_heredoc
            CREATE OR REPLACE FUNCTION test_schema.test()
             RETURNS text
             LANGUAGE plpgsql
            AS $function$
            BEGIN
                RETURN 'test';
            END;
            $function$
          EOS
        ensure
          ActiveRecord::Base.connection.execute 'SET search_path TO "$user", public'
        end
      end

      context 'when the other schema is the "$user" (dynamic) schema' do
        it "returns the `Function` objects" do
          connection = ActiveRecord::Base.connection
          current_user = connection.execute("SELECT current_user").first["current_user"]
          connection.execute <<-EOS.strip_heredoc
            CREATE SCHEMA #{current_user};
            SET search_path TO "$user",public;
            CREATE OR REPLACE FUNCTION #{current_user}.test()
            RETURNS text AS $$
            BEGIN
                RETURN 'test';
            END;
            $$ LANGUAGE plpgsql;
          EOS

          functions = Fx::Adapters::Postgres::Functions.new(connection).all

          first = functions.first
          expect(functions.size).to eq 1
          expect(first.name).to eq "test"
          expect(first.definition).to eq <<-EOS.strip_heredoc
            CREATE OR REPLACE FUNCTION #{current_user}.test()
             RETURNS text
             LANGUAGE plpgsql
            AS $function$
            BEGIN
                RETURN 'test';
            END;
            $function$
          EOS
        ensure
          ActiveRecord::Base.connection.execute 'SET search_path TO "$user", public'
        end
      end
    end
  end
end
