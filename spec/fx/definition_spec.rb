require "spec_helper"

describe Fx::Definition do
  describe "#to_sql" do
    let(:sql_definition) { <<-EOS }
      CREATE OR REPLACE FUNCTION test()
        RETURNS text AS $$
        BEGIN
            RETURN 'test';
        END;
        $$ LANGUAGE plpgsql;
    EOS

    context "representing a function definition" do
      it "returns the content of a function definition" do
        allow(File).to receive(:read).and_return(sql_definition)

        definition = Fx::Definition.new(name: "test", version: 1)

        expect(definition.to_sql).to eq sql_definition
      end

      it "raises an error if the file is empty" do
        allow(File).to receive(:read).and_return("")
        definition = Fx::Definition.new(name: "test", version: 1)

        expect { definition.to_sql }.to raise_error(
          RuntimeError,
          %r(Define function in db/functions/test_v01.sql before migrating),
        )
      end

      context "when definition is at Rails engine" do
        let(:engine_path) { Rails.root.join("tmp", "engine") }
        let(:definition_path) { engine_path.join("db", "functions", "custom_test_v01.sql") }

        before do
          FileUtils.mkdir_p(engine_path.join("db", "functions"))

          File.write(definition_path, sql_definition)

          Rails.application.config.paths["db/migrate"].push(engine_path.join("db", "migrate"))
        end

        after do
          FileUtils.rm_rf(engine_path)
        end

        it "returns the content of a function definition" do
          definition = Fx::Definition.new(name: "custom_test", version: 1)

          expect(definition.to_sql).to eq sql_definition
        end
      end
    end

    context "representing a trigger definition" do
      it "returns the content of a trigger definition" do
        sql_definition = <<-EOS
          CREATE TRIGGER check_update
          BEFORE UPDATE ON accounts
          FOR EACH ROW
          EXECUTE PROCEDURE check_account_update();
        EOS
        allow(File).to receive(:read).and_return(sql_definition)

        definition = Fx::Definition.new(
          name: "test",
          version: 1,
          type: "trigger",
        )

        expect(definition.to_sql).to eq sql_definition
      end

      it "raises an error if the file is empty" do
        allow(File).to receive(:read).and_return("")
        definition = Fx::Definition.new(
          name: "test",
          version: 1,
          type: "trigger",
        )

        expect { definition.to_sql }.to raise_error(
          RuntimeError,
          %r(Define trigger in db/triggers/test_v01.sql before migrating),
        )
      end
    end
  end

  describe "#path" do
    context "representing a function definition" do
      it "returns a sql file with padded version and function name" do
        definition = Fx::Definition.new(name: "test", version: 1)

        expect(definition.path).to eq "db/functions/test_v01.sql"
      end
    end

    context "representing a trigger definition" do
      it "returns a sql file with padded version and trigger name" do
        definition = Fx::Definition.new(
          name: "test",
          version: 1,
          type: "trigger",
        )

        expect(definition.path).to eq "db/triggers/test_v01.sql"
      end
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
