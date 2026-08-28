require "spec_helper"

RSpec.describe Fx::Adapters::AbstractAdapter do
  describe "abstract interface" do
    it "raises NotImplementedError for #functions" do
      expect { subject.functions }.to raise_error(
        NotImplementedError,
        "functions must be implemented by #{described_class}"
      )
    end

    it "raises NotImplementedError for #triggers" do
      expect { subject.triggers }.to raise_error(
        NotImplementedError,
        "triggers must be implemented by #{described_class}"
      )
    end

    it "raises NotImplementedError for #create_function" do
      expect { subject.create_function("SQL") }.to raise_error(
        NotImplementedError,
        "create_function must be implemented by #{described_class}"
      )
    end

    it "raises NotImplementedError for #create_trigger" do
      expect { subject.create_trigger("SQL") }.to raise_error(
        NotImplementedError,
        "create_trigger must be implemented by #{described_class}"
      )
    end

    it "raises NotImplementedError for #update_function" do
      expect { subject.update_function("name", "SQL") }.to raise_error(
        NotImplementedError,
        "update_function must be implemented by #{described_class}"
      )
    end

    it "raises NotImplementedError for #update_trigger" do
      expect {
        subject.update_trigger("name", on: "table", sql_definition: "SQL")
      }.to raise_error(
        NotImplementedError,
        "update_trigger must be implemented by #{described_class}"
      )
    end

    it "raises NotImplementedError for #drop_function" do
      expect { subject.drop_function("name") }.to raise_error(
        NotImplementedError,
        "drop_function must be implemented by #{described_class}"
      )
    end

    it "raises NotImplementedError for #drop_trigger" do
      expect { subject.drop_trigger("name", on: "table") }.to raise_error(
        NotImplementedError,
        "drop_trigger must be implemented by #{described_class}"
      )
    end
  end
end
