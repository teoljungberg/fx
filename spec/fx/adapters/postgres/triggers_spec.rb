require "spec_helper"

module Fx
  module Adapters
    describe Postgres::Triggers, :db do
      describe ".all" do
        it "returns `Trigger` objects" do
          connection = ActiveRecord::Base.connection
          connection.execute <<-SQL.strip_heredoc
            CREATE TABLE users (
                id int PRIMARY KEY,
                name varchar(256),
                upper_name varchar(256)
            );
          SQL
          connection.execute <<-SQL.strip_heredoc
            CREATE OR REPLACE FUNCTION uppercase_users_name()
            RETURNS trigger AS $$
            BEGIN
              NEW.upper_name = UPPER(NEW.name);
              RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
          SQL
          connection.execute <<-SQL.strip_heredoc
            CREATE TRIGGER uppercase_users_name
                BEFORE INSERT ON users
                FOR EACH ROW
                EXECUTE PROCEDURE uppercase_users_name();
          SQL

          triggers = Postgres::Triggers.new(connection).all

          first = triggers.first
          expect(triggers.size).to eq 1
          expect(first.name).to eq "uppercase_users_name"
          expect(first.definition).to include("BEFORE INSERT")
          expect(first.definition).to match(/ON [public\.users|users]/)
          expect(first.definition).to include("FOR EACH ROW")
          expect(first.definition).to include(
            "EXECUTE PROCEDURE uppercase_users_name()",
          )
        end
      end
    end
  end
end
