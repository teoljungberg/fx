require "spec_helper"
require "fx/generators/version_helper"

RSpec.describe Fx::Generators::VersionHelper do
  describe "#previous_version" do
    it "returns 0 when no existing versions found" do
      temp_dir = create_temp_directory
      helper = described_class.new("test_function", temp_dir)

      expect(helper.previous_version).to eq(0)
    end

    it "returns highest version number from existing files" do
      temp_dir = create_temp_directory
      create_version_file(temp_dir, "test_function", 1)
      create_version_file(temp_dir, "test_function", 3)
      create_version_file(temp_dir, "test_function", 2)

      helper = described_class.new("test_function", temp_dir)

      expect(helper.previous_version).to eq(3)
    end

    it "ignores files that don't match the pattern" do
      temp_dir = create_temp_directory
      create_version_file(temp_dir, "test_function", 2)
      FileUtils.touch(temp_dir.join("other_function_v3.sql"))
      FileUtils.touch(temp_dir.join("test_function.sql"))

      helper = described_class.new("test_function", temp_dir)

      expect(helper.previous_version).to eq(2)
    end
  end

  describe "#current_version" do
    it "returns previous version + 1" do
      temp_dir = create_temp_directory
      create_version_file(temp_dir, "test_function", 5)

      helper = described_class.new("test_function", temp_dir)

      expect(helper.current_version).to eq(6)
    end

    it "returns 1 when no previous versions exist" do
      temp_dir = create_temp_directory
      helper = described_class.new("test_function", temp_dir)

      expect(helper.current_version).to eq(1)
    end
  end

  describe "#updating_existing?" do
    it "returns false when no previous versions exist" do
      temp_dir = create_temp_directory
      helper = described_class.new("test_function", temp_dir)

      expect(helper.updating_existing?).to be false
    end

    it "returns true when previous versions exist" do
      temp_dir = create_temp_directory
      create_version_file(temp_dir, "test_function", 1)

      helper = described_class.new("test_function", temp_dir)

      expect(helper.updating_existing?).to be true
    end
  end

  describe "#creating_new?" do
    it "returns true when no previous versions exist" do
      temp_dir = create_temp_directory
      helper = described_class.new("test_function", temp_dir)

      expect(helper.creating_new?).to be true
    end

    it "returns false when previous versions exist" do
      temp_dir = create_temp_directory
      create_version_file(temp_dir, "test_function", 1)

      helper = described_class.new("test_function", temp_dir)

      expect(helper.creating_new?).to be false
    end
  end

  describe "#definition_for_version" do
    it "returns function definition for function type" do
      temp_dir = create_temp_directory
      helper = described_class.new("test_function", temp_dir)
      allow(Fx::Definition).to receive(:function)
        .and_return("function_definition")

      result = helper.definition_for_version(2, :function)

      expect(result).to eq("function_definition")
      expect(Fx::Definition).to have_received(:function).with(
        name: "test_function",
        version: 2
      )
    end

    it "returns trigger definition for trigger type" do
      temp_dir = create_temp_directory
      helper = described_class.new("test_trigger", temp_dir)
      allow(Fx::Definition).to receive(:trigger)
        .and_return("trigger_definition")

      result = helper.definition_for_version(3, :trigger)

      expect(result).to eq("trigger_definition")
      expect(Fx::Definition).to have_received(:trigger).with(
        name: "test_trigger",
        version: 3
      )
    end

    it "raises error for unknown type" do
      temp_dir = create_temp_directory
      helper = described_class.new("test_function", temp_dir)

      expect {
        helper.definition_for_version(1, :unknown)
      }.to raise_error(
        ArgumentError,
        "Unknown type: unknown. Must be :function or :trigger"
      )
    end
  end

  private

  def create_temp_directory
    Dir.mktmpdir.yield_self { |path| Pathname.new(path) }
  end

  def create_version_file(dir, name, version)
    FileUtils.touch(dir.join("#{name}_v#{version}.sql"))
  end
end
