require "spec_helper"
require "fx/generators/migration_helper"

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

  describe "#active_record_migration_class" do
    it "returns versioned migration class when current_version is available" do
      allow(ActiveRecord::Migration).to receive(:respond_to?)
        .with(:current_version)
        .and_return(true)
      allow(ActiveRecord::Migration).to receive(:current_version)
        .and_return(7.0)

      helper = described_class.new({})

      expect(helper.active_record_migration_class).to eq("ActiveRecord::Migration[7.0]")
    end

    it "returns base migration class when current_version is not available" do
      allow(ActiveRecord::Migration).to receive(:respond_to?)
        .with(:current_version)
        .and_return(false)

      helper = described_class.new({})

      expect(helper.active_record_migration_class).to eq("ActiveRecord::Migration")
    end
  end

  describe "#update_migration_class_name" do
    it "generates correct class name for functions" do
      helper = described_class.new({})

      result = helper.update_migration_class_name(:function, "TestFunction", 3)

      expect(result).to eq("UpdateFunctionTestFunctionToVersion3")
    end

    it "generates correct class name for triggers" do
      helper = described_class.new({})

      result = helper.update_migration_class_name(:trigger, "TestTrigger", 2)

      expect(result).to eq("UpdateTriggerTestTriggerToVersion2")
    end
  end

  describe "#migration_template_info" do
    it "returns create template info for new objects" do
      helper = described_class.new({})

      result = helper.migration_template_info(:function, "test_func", false, 1)

      expect(result).to eq({
        template: "db/migrate/create_function.erb",
        filename: "db/migrate/create_function_test_func.rb"
      })
    end

    it "returns update template info for existing objects" do
      helper = described_class.new({})

      result = helper.migration_template_info(:trigger, "test_trigger", true, 3)

      expect(result).to eq({
        template: "db/migrate/update_trigger.erb",
        filename: "db/migrate/update_trigger_test_trigger_to_version_3.rb"
      })
    end

    it "handles different object types correctly" do
      helper = described_class.new({})

      function_result = helper.migration_template_info(:function, "my_func", true, 2)
      trigger_result = helper.migration_template_info(:trigger, "my_trigger", true, 2)

      expect(function_result[:template]).to eq("db/migrate/update_function.erb")
      expect(trigger_result[:template]).to eq("db/migrate/update_trigger.erb")
      expect(function_result[:filename]).to include("function")
      expect(trigger_result[:filename]).to include("trigger")
    end
  end
end
