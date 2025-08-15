require "spec_helper"
require "fx/generators/version_calculator"

RSpec.describe Fx::Generators::VersionCalculator do
  describe "#previous_version" do
    it "returns 0 when no definition files exist" do
      definition_path = create_temp_directory

      calculator = described_class.new("test_func", definition_path)

      expect(calculator.previous_version).to eq(0)
    end

    it "finds the highest version from existing files" do
      definition_path = create_temp_directory
      create_file(definition_path.join("test_func_v01.sql"))
      create_file(definition_path.join("test_func_v03.sql"))
      create_file(definition_path.join("test_func_v02.sql"))

      calculator = described_class.new("test_func", definition_path)

      expect(calculator.previous_version).to eq(3)
    end

    it "ignores files that don't match the pattern" do
      definition_path = create_temp_directory
      create_file(definition_path.join("test_func_v01.sql"))
      create_file(definition_path.join("test_func.sql"))       # missing version
      create_file(definition_path.join("test_func_v02.txt"))   # wrong extension
      create_file(definition_path.join("test_func_vXX.sql"))   # non-numeric version

      calculator = described_class.new("test_func", definition_path)

      expect(calculator.previous_version).to eq(1)
    end

    it "handles function names with special characters" do
      definition_path = create_temp_directory
      create_file(definition_path.join("test.func_v01.sql"))
      create_file(definition_path.join("test.func_v02.sql"))

      calculator = described_class.new("test.func", definition_path)

      expect(calculator.previous_version).to eq(2)
    end
  end

  describe "#current_version" do
    it "returns 1 for new functions" do
      definition_path = create_temp_directory

      calculator = described_class.new("test_func", definition_path)

      expect(calculator.current_version).to eq(1)
    end

    it "returns next version for existing functions" do
      definition_path = create_temp_directory
      create_file(definition_path.join("test_func_v03.sql"))

      calculator = described_class.new("test_func", definition_path)

      expect(calculator.current_version).to eq(4)
    end
  end

  describe "#updating_existing?" do
    it "returns false for new functions" do
      definition_path = create_temp_directory

      calculator = described_class.new("test_func", definition_path)

      expect(calculator.updating_existing?).to be(false)
    end

    it "returns true for existing functions" do
      definition_path = create_temp_directory
      create_file(definition_path.join("test_func_v01.sql"))

      calculator = described_class.new("test_func", definition_path)

      expect(calculator.updating_existing?).to be(true)
    end
  end

  describe "#creating_new?" do
    it "returns true for new functions" do
      definition_path = create_temp_directory

      calculator = described_class.new("test_func", definition_path)

      expect(calculator.creating_new?).to be(true)
    end

    it "returns false for existing functions" do
      definition_path = create_temp_directory
      create_file(definition_path.join("test_func_v01.sql"))

      calculator = described_class.new("test_func", definition_path)

      expect(calculator.creating_new?).to be(false)
    end
  end

  describe "#version_glob_pattern" do
    it "returns the correct glob pattern" do
      calculator = described_class.new("test_func", "/path")

      expect(calculator.version_glob_pattern).to eq("test_func_v*.sql")
    end
  end

  describe "#definition_for_version" do
    it "delegates to Fx::Definition for functions" do
      allow(Fx::Definition).to receive(:function)
        .with(name: "test_func", version: 2)
        .and_return(double("definition"))

      calculator = described_class.new("test_func", "/path")

      result = calculator.definition_for_version(2, :function)

      expect(result).to be_a(RSpec::Mocks::Double)
      expect(Fx::Definition).to have_received(:function)
        .with(name: "test_func", version: 2)
    end

    it "delegates to Fx::Definition for triggers" do
      allow(Fx::Definition).to receive(:trigger)
        .with(name: "test_trigger", version: 3)
        .and_return(double("definition"))

      calculator = described_class.new("test_trigger", "/path")

      result = calculator.definition_for_version(3, :trigger)

      expect(result).to be_a(RSpec::Mocks::Double)
      expect(Fx::Definition).to have_received(:trigger)
        .with(name: "test_trigger", version: 3)
    end
  end

  private

  def create_temp_directory
    Dir.mktmpdir.yield_self { |path| Pathname.new(path) }
  end

  def create_file(path)
    FileUtils.touch(path)
  end
end
