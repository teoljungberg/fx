require "spec_helper"
require "fx/view"

module Fx
  describe View do
    describe "#<=>" do
      it "delegates to `name`" do
        view_a = View.new(
          "name" => "name_a",
          "definition" => "some defintion"
        )
        view_b = View.new(
          "name" => "name_b",
          "definition" => "some defintion"
        )
        view_c = View.new(
          "name" => "name_c",
          "definition" => "some defintion"
        )

        expect(view_b).to be_between(view_a, view_c)
      end
    end

    describe "#==" do
      it "compares `name` and `definition`" do
        view_a = View.new(
          "name" => "name_a",
          "definition" => "some defintion"
        )
        view_b = View.new(
          "name" => "name_b",
          "definition" => "some other defintion"
        )

        expect(view_a).not_to eq(view_b)
      end
    end

    describe "#to_schema" do
      context "when it is a materialized view" do
        it "returns a schema compatible version of the materialized view" do
          view = View.new(
            "name" => "active_users",
            "definition" => "SELECT * FROM users ...",
            "materialized" => true
          )

          expect(view.to_schema).to eq <<-EOS
  create_view :active_users, sql_definition: <<-\SQL
      CREATE MATERIALIZED VIEW active_users AS
      SELECT * FROM users ...
  SQL
          EOS
        end
      end

      context "when it is not a materialized view" do
        it "returns a schema compatible version of the view" do
          view = View.new(
            "name" => "active_users",
            "definition" => "SELECT * FROM users ..."
          )

          expect(view.to_schema).to eq <<-EOS
  create_view :active_users, sql_definition: <<-\SQL
      CREATE VIEW active_users AS
      SELECT * FROM users ...
  SQL
          EOS
        end
      end
    end
  end
end
