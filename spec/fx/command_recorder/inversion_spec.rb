require "spec_helper"

RSpec.describe Fx::CommandRecorder::Inversion do
  describe ".invert" do
    it "drops a created function" do
      inverse = described_class.invert(:create_function, [:test], {})

      expect(inverse).to eq([:drop_function, [:test], {}])
    end

    it "drops a created function without its version" do
      inverse = described_class.invert(:create_function, [:test], {version: 2})

      expect(inverse).to eq([:drop_function, [:test], {}])
    end

    it "creates a dropped function at its revert_to_version" do
      inverse = described_class.invert(:drop_function, [:test], {revert_to_version: 3})

      expect(inverse).to eq([:create_function, [:test], {version: 3}])
    end

    it "updates an updated function back to its revert_to_version" do
      inverse = described_class.invert(:update_function, [:test], {version: 2, revert_to_version: 1})

      expect(inverse).to eq([:update_function, [:test], {version: 1}])
    end

    it "drops a created trigger on its table" do
      inverse = described_class.invert(:create_trigger, [:greetings], {on: :users})

      expect(inverse).to eq([:drop_trigger, [:greetings], {on: :users}])
    end

    it "raises when a created trigger has no table" do
      expect do
        described_class.invert(:create_trigger, [:greetings], {})
      end.to raise_error(ActiveRecord::IrreversibleMigration, /`on:`/)
    end

    it "drops a created trigger on its table without its version" do
      inverse = described_class.invert(:create_trigger, [:greetings], {on: :users, version: 2})

      expect(inverse).to eq([:drop_trigger, [:greetings], {on: :users}])
    end

    it "creates a dropped trigger at its revert_to_version" do
      inverse = described_class.invert(:drop_trigger, [:greetings], {on: :users, revert_to_version: 3})

      expect(inverse).to eq([:create_trigger, [:greetings], {on: :users, version: 3}])
    end

    it "updates an updated trigger back to its revert_to_version" do
      inverse = described_class.invert(:update_trigger, [:greetings], {on: :users, version: 2, revert_to_version: 1})

      expect(inverse).to eq([:update_trigger, [:greetings], {on: :users, version: 1}])
    end

    it "raises when a drop has no revert_to_version" do
      expect do
        described_class.invert(:drop_function, [:test], {})
      end.to raise_error(ActiveRecord::IrreversibleMigration, /`create_function`/)
    end

    it "raises when an update has no revert_to_version" do
      expect do
        described_class.invert(:update_trigger, [:greetings], {version: 2})
      end.to raise_error(ActiveRecord::IrreversibleMigration, /`update_trigger`/)
    end

    it "raises for a command fx does not record" do
      expect do
        described_class.invert(:create_table, [:users], {})
      end.to raise_error(ArgumentError, /`create_table` is not an fx command/)
    end
  end
end
