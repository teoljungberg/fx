require "spec_helper"
require "generators/fx/migration_helper"

RSpec.describe Fx::Generators::MigrationHelper do
  describe "#skip_creation?" do
    it "returns false by default" do
      helper = described_class.new({})

      expect(helper.skip_creation?).to be(false)
    end

    it "returns true when migration option is false" do
      helper = described_class.new(migration: false)

      expect(helper.skip_creation?).to be(true)
    end
  end

  describe "#update_migration_class_name" do
    it "generates correct class name for functions" do
      helper = described_class.new({})

      result = helper.update_migration_class_name(
        object_type: :function,
        class_name: "Value",
        version: 3
      )

      expect(result).to eq("UpdateFunctionValueToVersion3")
    end

    it "generates correct class name for triggers" do
      helper = described_class.new({})

      result = helper.update_migration_class_name(
        object_type: :trigger,
        class_name: "SetUpperName",
        version: 2
      )

      expect(result).to eq("UpdateTriggerSetUpperNameToVersion2")
    end
  end

  describe "#migration_template_info" do
    it "returns create template info for new objects" do
      helper = described_class.new({})

      result = helper.migration_template_info(
        object_type: :function,
        file_name: "value",
        updating_existing: false,
        version: 1
      )

      expect(result).to eq({
        template: "db/migrate/create_function.erb",
        filename: "db/migrate/create_function_value.rb"
      })
    end

    it "returns update template info for existing objects" do
      helper = described_class.new({})

      result = helper.migration_template_info(
        object_type: :trigger,
        file_name: "set_upper_name",
        updating_existing: true,
        version: 3
      )

      expect(result).to eq({
        template: "db/migrate/update_trigger.erb",
        filename: "db/migrate/update_trigger_set_upper_name_to_version_3.rb"
      })
    end

    it "handles different object types correctly" do
      helper = described_class.new({})

      function_result = helper.migration_template_info(
        object_type: :function,
        file_name: "add",
        updating_existing: true,
        version: 2
      )
      trigger_result = helper.migration_template_info(
        object_type: :trigger,
        file_name: "set_lower_name",
        updating_existing: true,
        version: 2
      )

      expect(function_result.fetch(:template)).to eq(
        "db/migrate/update_function.erb"
      )
      expect(trigger_result.fetch(:template)).to eq(
        "db/migrate/update_trigger.erb"
      )
      expect(function_result.fetch(:filename)).to eq(
        "db/migrate/update_function_add_to_version_2.rb"
      )
      expect(trigger_result.fetch(:filename)).to eq(
        "db/migrate/update_trigger_set_lower_name_to_version_2.rb"
      )
    end
  end
end
