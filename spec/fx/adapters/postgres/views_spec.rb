require "spec_helper"

module Fx
  module Adapters
    describe Postgres::Views, :db do
      describe ".all" do
        it "returns `View` objects" do
          connection = ActiveRecord::Base.connection
          connection.execute <<-EOS.strip_heredoc
            CREATE TABLE users (
                id int PRIMARY KEY,
                name varchar(256),
                upper_name varchar(256),
                active boolean
            );

            CREATE VIEW active_users AS
              SELECT * FROM users WHERE active = true;
          EOS

          views = Postgres::Views.new(connection).all

          first = views.first
          expect(views.size).to eq 1
          expect(first.name).to eq "active_users"
          expect(first.definition).to eq <<-EOS.strip_heredoc.rstrip
           SELECT users.id,
               users.name,
               users.upper_name,
               users.active
              FROM users
             WHERE (users.active = true);
          EOS
        end
      end
    end
  end
end
