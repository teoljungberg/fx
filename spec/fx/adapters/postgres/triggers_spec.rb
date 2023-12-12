require "spec_helper"

RSpec.describe Fx::Adapters::Postgres::Triggers, :db do
  describe ".all" do
    it "returns `Trigger` objects" do
      connection = ActiveRecord::Base.connection
      connection.execute <<-EOS.strip_heredoc
        CREATE TABLE users (
            id int PRIMARY KEY,
            first_name varchar(256),
            last_name varchar(256),
            upper_first_name varchar(256),
            upper_last_name varchar(256)
        );
      EOS
      connection.execute <<-EOS.strip_heredoc
        CREATE OR REPLACE FUNCTION uppercase_users_first_name()
        RETURNS trigger AS $$
        BEGIN
          NEW.upper_first_name = UPPER(NEW.first_name);
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      EOS
      connection.execute <<-EOS.strip_heredoc
        CREATE OR REPLACE FUNCTION uppercase_users_last_name()
        RETURNS trigger AS $$
        BEGIN
          NEW.upper_last_name = UPPER(NEW.last_name);
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      EOS
      connection.execute <<-EOS.strip_heredoc
        CREATE TRIGGER uppercase_users_first_name
            BEFORE INSERT ON users
            FOR EACH ROW
            EXECUTE FUNCTION uppercase_users_first_name();
      EOS
      connection.execute <<-EOS.strip_heredoc
        CREATE TRIGGER uppercase_users_last_name
            BEFORE INSERT ON users
            FOR EACH ROW
            EXECUTE FUNCTION uppercase_users_last_name();
      EOS

      triggers = Fx::Adapters::Postgres::Triggers.new(connection).all

      expect(triggers).to match(
        [
          an_object_having_attributes(name: "uppercase_users_first_name", definition: a_string_matching(/EXECUTE FUNCTION uppercase_users_first_name()/)),
          an_object_having_attributes(name: "uppercase_users_last_name", definition: a_string_matching(/EXECUTE FUNCTION uppercase_users_last_name()/))
        ]
      )
    end
  end
end
