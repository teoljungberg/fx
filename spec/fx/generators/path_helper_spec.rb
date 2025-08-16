require "spec_helper"
require "fx/generators/path_helper"

RSpec.describe Fx::Generators::PathHelper do
  describe ".definition_path_for" do
    it "returns function path for function type" do
      allow(Rails).to receive(:root).and_return(Pathname.new("/app"))

      result = described_class.definition_path_for(:function)

      expect(result.to_s).to eq("/app/db/functions")
    end

    it "returns trigger path for trigger type" do
      allow(Rails).to receive(:root).and_return(Pathname.new("/app"))

      result = described_class.definition_path_for(:trigger)

      expect(result.to_s).to eq("/app/db/triggers")
    end

    it "raises error for unknown object types" do
      expect {
        described_class.definition_path_for(:unknown)
      }.to raise_error(ArgumentError, "Unknown object type: unknown")
    end

    it "raises error for nil object type" do
      expect {
        described_class.definition_path_for(nil)
      }.to raise_error(ArgumentError, "Unknown object type: ")
    end
  end

  describe ".ensure_directory_exists" do
    it "does not create directory when path exists" do
      path = double("path", exist?: true)
      generator = double("generator")
      allow(generator).to receive(:empty_directory)

      described_class.ensure_directory_exists(generator, path)

      expect(generator).not_to have_received(:empty_directory)
    end

    it "creates directory when path does not exist" do
      path = double("path", exist?: false)
      generator = double("generator")
      allow(generator).to receive(:empty_directory)

      described_class.ensure_directory_exists(generator, path)

      expect(generator).to have_received(:empty_directory).with(path)
    end

    it "works with Pathname objects" do
      temp_dir = Dir.mktmpdir
      path = Pathname.new(temp_dir).join("nonexistent")
      generator = double("generator")
      allow(generator).to receive(:empty_directory)

      described_class.ensure_directory_exists(generator, path)

      expect(generator).to have_received(:empty_directory).with(path)

      FileUtils.rm_rf(temp_dir)
    end
  end
end
