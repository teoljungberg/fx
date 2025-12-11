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
        class_name: "TestFunction",
        version: 3
      )

      expect(result).to eq("UpdateFunctionTestFunctionToVersion3")
    end

    it "generates correct class name for triggers" do
      helper = described_class.new({})

      result = helper.update_migration_class_name(
        object_type: :trigger,
        class_name: "TestTrigger",
        version: 2
      )

      expect(result).to eq("UpdateTriggerTestTriggerToVersion2")
    end
  end

  describe "#migration_template_info" do
    it "returns create template info for new objects" do
      helper = described_class.new({})

      result = helper.migration_template_info(
        object_type: :function,
        file_name: "test_func",
        updating_existing: false,
        version: 1
      )

      expect(result).to eq({
        template: "db/migrate/create_function.erb",
        filename: "db/migrate/create_function_test_func.rb"
      })
    end

    it "returns update template info for existing objects" do
      helper = described_class.new({})

      result = helper.migration_template_info(
        object_type: :trigger,
        file_name: "test_trigger",
        updating_existing: true,
        version: 3
      )

      expect(result).to eq({
        template: "db/migrate/update_trigger.erb",
        filename: "db/migrate/update_trigger_test_trigger_to_version_3.rb"
      })
    end

    it "handles different object types correctly" do
      helper = described_class.new({})

      function_result = helper.migration_template_info(
        object_type: :function,
        file_name: "my_function",
        updating_existing: true,
        version: 2
      )
      trigger_result = helper.migration_template_info(
        object_type: :trigger,
        file_name: "my_trigger",
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
        "db/migrate/update_function_my_function_to_version_2.rb"
      )
      expect(trigger_result.fetch(:filename)).to eq(
        "db/migrate/update_trigger_my_trigger_to_version_2.rb"
      )
    end
  end
end
