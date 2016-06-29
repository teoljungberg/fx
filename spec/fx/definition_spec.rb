require "spec_helper"

describe Fx::Definition do
  describe "#to_sql" do
    it "returns the content of a function definition" do
      sql_definition = <<~EOS
        CREATE OR REPLACE FUNCTION test() RETURNS text AS $$
        BEGIN
            RETURN 'test';
        END;
        $$ LANGUAGE plpgsql;
      EOS
      allow(File).to receive(:read).and_return(sql_definition)

      definition = Fx::Definition.new(name: "test", version: 1)

      expect(definition.to_sql).to eq sql_definition
    end

    it "raises an error if the file is empty" do
      allow(File).to receive(:read).and_return("")

      expect { Fx::Definition.new(name: "test", version: 1).to_sql }.
        to raise_error RuntimeError
    end
  end

  describe "#path" do
    it "returns a sql file with padded version and function name" do
      definition = Fx::Definition.new(name: "test", version: 1)

      expect(definition.path).to eq "db/functions/test_v01.sql"
    end
  end

  describe "#full_path" do
    it "joins the path with Rails.root" do
      definition = Fx::Definition.new(name: "test", version: 15)

      expect(definition.full_path).to eq Rails.root.join(definition.path)
    end
  end

  describe "#version" do
    it "pads the version number with 0" do
      definition = Fx::Definition.new(name: :_, version: 1)

      expect(definition.version).to eq "01"
    end

    it "does not pad more than 2 characters" do
      definition = Fx::Definition.new(name: :_, version: 15)

      expect(definition.version).to eq "15"
    end
  end
end
