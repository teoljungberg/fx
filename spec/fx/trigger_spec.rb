require "spec_helper"
require "fx/trigger"

module Fx
  describe Trigger do
    describe "#<=>" do
      it "delegates to `name`" do
        trigger_a = Trigger.new(
          "name" => "name_a",
          "definition" => "some defintion",
        )
        trigger_b = Trigger.new(
          "name" => "name_b",
          "definition" => "some defintion",
        )
        trigger_c = Trigger.new(
          "name" => "name_c",
          "definition" => "some defintion",
        )

        expect(trigger_b).to be_between(trigger_a, trigger_c)
      end
    end

    describe "#==" do
      it "compares `name` and `definition`" do
        trigger_a = Trigger.new(
          "name" => "name_a",
          "definition" => "some defintion",
        )
        trigger_b = Trigger.new(
          "name" => "name_b",
          "definition" => "some other defintion",
        )

        expect(trigger_a).not_to eq(trigger_b)
      end
    end

    describe "#to_schema" do
      it "returns a schema compatible version of the trigger" do
        trigger = Trigger.new(
          "name" => "uppercase_users_name",
          "definition" => "CREATE TRIGGER uppercase_users_name ...",
        )

        expect(trigger.to_schema).to eq <<-TRIGGER
  create_trigger :uppercase_users_name, sql_definition: <<-\SQL
      CREATE TRIGGER uppercase_users_name ...
  SQL
        TRIGGER
      end
    end
  end
end
