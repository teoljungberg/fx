require "spec_helper"
require "generators/fx/name_helper"

RSpec.describe Fx::Generators::NameHelper do
  describe ".format_for_migration" do
    it "returns symbol format for simple names" do
      result = described_class.format_for_migration("simple_name")

      expect(result).to eq(":simple_name")
    end

    it "returns quoted string format for schema-qualified names" do
      result = described_class.format_for_migration("schema.function_name")

      expect(result).to eq("\"schema.function_name\"")
    end

    it "handles names with multiple dots" do
      result = described_class.format_for_migration("db.schema.function")

      expect(result).to eq("\"db.schema.function\"")
    end

    it "handles empty names" do
      result = described_class.format_for_migration("")

      expect(result).to eq(":")
    end
  end

  describe ".format_table_name_from_hash" do
    it "formats table_name key correctly" do
      table_hash = {"table_name" => "users"}

      result = described_class.format_table_name_from_hash(table_hash)

      expect(result).to eq(":users")
    end

    it "formats on key correctly" do
      table_hash = {"on" => "posts"}

      result = described_class.format_table_name_from_hash(table_hash)

      expect(result).to eq(":posts")
    end

    it "prefers table_name over on when both are present" do
      table_hash = {"table_name" => "users", "on" => "posts"}

      result = described_class.format_table_name_from_hash(table_hash)

      expect(result).to eq(":users")
    end

    it "handles schema-qualified table names" do
      table_hash = {"table_name" => "public.users"}

      result = described_class.format_table_name_from_hash(table_hash)

      expect(result).to eq("\"public.users\"")
    end

    it "raises error when neither key is present" do
      table_hash = {"something_else" => "value"}

      expect {
        described_class.format_table_name_from_hash(table_hash)
      }.to raise_error(
        ArgumentError,
        "Either `table_name:NAME` or `on:NAME` must be specified"
      )
    end

    it "raises error when both keys have nil values" do
      table_hash = {"table_name" => nil, "on" => nil}

      expect {
        described_class.format_table_name_from_hash(table_hash)
      }.to raise_error(
        ArgumentError,
        "Either `table_name:NAME` or `on:NAME` must be specified"
      )
    end

    it "uses on key when table_name is nil" do
      table_hash = {"table_name" => nil, "on" => "comments"}

      result = described_class.format_table_name_from_hash(table_hash)

      expect(result).to eq(":comments")
    end
  end

  describe ".validate_and_format" do
    it "formats valid names correctly" do
      result = described_class.validate_and_format("test_function")

      expect(result).to eq(":test_function")
    end

    it "formats schema-qualified names correctly" do
      result = described_class.validate_and_format("schema.test")

      expect(result).to eq("\"schema.test\"")
    end

    it "raises error for blank names" do
      expect {
        described_class.validate_and_format("")
      }.to raise_error(ArgumentError, "Name cannot be blank")
    end
  end
end
