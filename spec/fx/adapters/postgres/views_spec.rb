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

            CREATE MATERIALIZED VIEW mat_active_users AS
              SELECT * FROM users WHERE active = true;
          EOS

          views = Postgres::Views.new(connection).all

          view = views.first
          expect(views.size).to eq 2
          expect(view.name).to eq "active_users"
          expect(view.definition).to eq <<-EOS.strip_heredoc.rstrip
           SELECT users.id,
               users.name,
               users.upper_name,
               users.active
              FROM users
             WHERE (users.active = true);
          EOS

          materialized_view = views.last
          expect(materialized_view.name).to eq "mat_active_users"
          expect(materialized_view.definition).to eq <<-EOS.strip_heredoc.rstrip
           SELECT users.id,
               users.name,
               users.upper_name,
               users.active
              FROM users
             WHERE (users.active = true);
          EOS
        end

        it "returns `View` objects for materialized view including indexes definitions" do
          connection = ActiveRecord::Base.connection
          connection.execute <<-EOS.strip_heredoc
            CREATE TABLE users (
                id int PRIMARY KEY,
                name varchar(256),
                upper_name varchar(256),
                active boolean
            );

            CREATE MATERIALIZED VIEW mat_active_users AS
              SELECT * FROM users WHERE active = true;

            CREATE INDEX mat_active_users_id_index ON mat_active_users (name);
          EOS

          views = Postgres::Views.new(connection).all

          materialized_view = views.last
          expect(views.size).to eq 1
          expect(materialized_view.name).to eq "mat_active_users"
          expect(materialized_view.definition).to eq <<-EOS.strip_heredoc.rstrip
           SELECT users.id,
               users.name,
               users.upper_name,
               users.active
              FROM users
             WHERE (users.active = true);

           CREATE INDEX mat_active_users_id_index ON public.mat_active_users USING btree (name);
          EOS
        end
      end
    end
  end
end
