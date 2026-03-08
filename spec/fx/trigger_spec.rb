require "spec_helper"

RSpec.describe Fx::Trigger do
  describe "#<=>" do
    it "delegates to `name`" do
      trigger_a = Fx::Trigger.new(
        "name" => "name_a",
        "definition" => "some definition"
      )
      trigger_b = Fx::Trigger.new(
        "name" => "name_b",
        "definition" => "some definition"
      )
      trigger_c = Fx::Trigger.new(
        "name" => "name_c",
        "definition" => "some definition"
      )

      expect(trigger_b).to be_between(trigger_a, trigger_c)
    end
  end

  describe "#==" do
    it "compares `name` and `definition`" do
      trigger_a = Fx::Trigger.new(
        "name" => "name_a",
        "definition" => "some definition"
      )
      trigger_b = Fx::Trigger.new(
        "name" => "name_b",
        "definition" => "some other definition"
      )

      expect(trigger_a).not_to eq(trigger_b)
    end
  end

  describe "#to_schema" do
    it "returns a schema compatible version of the trigger" do
      trigger = Fx::Trigger.new(
        "name" => "set_upper_name",
        "definition" => "CREATE TRIGGER set_upper_name ..."
      )

      expect(trigger.to_schema).to eq(<<-EOS)
  create_trigger :set_upper_name, sql_definition: <<-\SQL
      CREATE TRIGGER set_upper_name ...
  SQL
      EOS
    end
  end
end
