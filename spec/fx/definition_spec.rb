require "spec_helper"

RSpec.describe Fx::Definition do
  describe "#to_sql" do
    context "representing a function definition" do
      it "returns the content of a function definition" do
        sql_definition = <<~SQL
          CREATE OR REPLACE FUNCTION value()
          RETURNS text AS $$
          BEGIN
              RETURN 'value';
          END;
          $$ LANGUAGE plpgsql;
        SQL
        allow(File).to receive(:read).and_return(sql_definition)

        definition = Fx::Definition.function(name: "value", version: 1)

        expect(definition.to_sql).to eq(sql_definition)
      end

      it "raises an error if the file is empty" do
        allow(File).to receive(:read).and_return("")
        definition = Fx::Definition.function(name: "value", version: 1)

        expect do
          definition.to_sql
        end.to raise_error(
          RuntimeError,
          %r{Define function in db/functions/value_v01.sql before migrating}
        )
      end

      context "when definition is at Rails engine" do
        it "returns the content of a function definition" do
          sql_definition = <<~SQL
            CREATE OR REPLACE FUNCTION value()
            RETURNS text AS $$
            BEGIN
                RETURN 'value';
            END;
            $$ LANGUAGE plpgsql;
          SQL
          engine_path = Rails.root.join("tmp", "engine")
          FileUtils.mkdir_p(engine_path.join("db", "functions"))
          File.write(engine_path.join("db", "functions", "custom_value_v01.sql"), sql_definition)
          Rails.application.config.paths["db/migrate"].push(engine_path.join("db", "migrate"))

          definition = Fx::Definition.function(name: "custom_value", version: 1)

          expect(definition.to_sql).to eq(sql_definition)

          FileUtils.rm_rf(engine_path)
        end
      end
    end

    context "representing a trigger definition" do
      it "returns the content of a trigger definition" do
        sql_definition = <<~SQL
          CREATE TRIGGER set_upper_name
          BEFORE INSERT ON users
          FOR EACH ROW
          EXECUTE FUNCTION set_upper_name();
        SQL
        allow(File).to receive(:read).and_return(sql_definition)

        definition = Fx::Definition.trigger(name: "set_upper_name", version: 1)

        expect(definition.to_sql).to eq(sql_definition)
      end

      it "raises an error if the file is empty" do
        allow(File).to receive(:read).and_return("")
        definition = Fx::Definition.trigger(name: "set_upper_name", version: 1)

        expect do
          definition.to_sql
        end.to raise_error(
          RuntimeError,
          %r{Define trigger in db/triggers/set_upper_name_v01.sql before migrating}
        )
      end
    end
  end

  describe "#path" do
    context "representing a function definition" do
      it "returns a sql file with padded version and function name" do
        definition = Fx::Definition.function(name: "value", version: 1)

        expect(definition.path).to eq("db/functions/value_v01.sql")
      end
    end

    context "representing a trigger definition" do
      it "returns a sql file with padded version and trigger name" do
        definition = Fx::Definition.trigger(name: "set_upper_name", version: 1)

        expect(definition.path).to eq("db/triggers/set_upper_name_v01.sql")
      end
    end
  end

  describe "#full_path" do
    it "joins the path with Rails.root" do
      definition = Fx::Definition.function(name: "value", version: 15)

      expect(definition.full_path).to eq(Rails.root.join(definition.path))
    end
  end

  describe "#version" do
    it "pads the version number with 0" do
      definition = Fx::Definition.function(name: :_, version: 1)

      expect(definition.version).to eq("01")
    end

    it "does not pad more than 2 characters" do
      definition = Fx::Definition.function(name: :_, version: 15)

      expect(definition.version).to eq("15")
    end
  end
end
