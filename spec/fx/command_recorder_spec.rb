require "spec_helper"

RSpec.describe "Fx command recorder", :db do
  describe "#create_function" do
    it "records the created function" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      migration = double("migration", create_function: nil)

      recorder.create_function :test
      recorder.replay(migration)

      expect(migration).to have_received(:create_function).with(:test)
    end

    it "reverts to drop_function" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      migration = double("migration", drop_function: nil)

      recorder.revert { recorder.create_function :test }
      recorder.replay(migration)

      expect(migration).to have_received(:drop_function).with(:test)
    end
  end

  describe "#drop_function" do
    it "records the dropped function" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      migration = double("migration", drop_function: nil)

      recorder.drop_function :test
      recorder.replay(migration)

      expect(migration).to have_received(:drop_function).with(:test)
    end

    it "reverts to create_function with specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      migration = double("migration", create_function: nil)

      recorder.revert { recorder.drop_function(:test, revert_to_version: 3) }
      recorder.replay(migration)

      expect(migration).to have_received(:create_function).with(:test, version: 3)
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      expect do
        recorder.revert { recorder.drop_function(:test, another_argument: 1) }
      end.to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#update_function" do
    it "records the updated function" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      migration = double("migration", update_function: nil)

      recorder.update_function(:test, version: 2)
      recorder.replay(migration)

      expect(migration).to have_received(:update_function).with(:test, version: 2)
    end

    it "reverts to update_function with the specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      migration = double("migration", update_function: nil)

      recorder.revert { recorder.update_function(:test, version: 2, revert_to_version: 1) }
      recorder.replay(migration)

      expect(migration).to have_received(:update_function).with(:test, version: 1)
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      expect do
        recorder.revert { recorder.update_function(:test, version: 42, another_argument: 1) }
      end.to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#create_trigger" do
    it "records the created trigger" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      migration = double("migration", create_trigger: nil)

      recorder.create_trigger :greetings
      recorder.replay(migration)

      expect(migration).to have_received(:create_trigger).with(:greetings)
    end

    it "reverts to drop_trigger" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      migration = double("migration", drop_trigger: nil)

      recorder.revert { recorder.create_trigger :greetings }
      recorder.replay(migration)

      expect(migration).to have_received(:drop_trigger).with(:greetings)
    end
  end

  describe "#drop_trigger" do
    it "records the dropped trigger" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      migration = double("migration", drop_trigger: nil)

      recorder.drop_trigger :users
      recorder.replay(migration)

      expect(migration).to have_received(:drop_trigger).with(:users)
    end

    it "reverts to create_trigger with specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      migration = double("migration", create_trigger: nil)

      recorder.revert { recorder.drop_trigger(:users, revert_to_version: 3) }
      recorder.replay(migration)

      expect(migration).to have_received(:create_trigger).with(:users, version: 3)
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      expect do
        recorder.revert { recorder.drop_trigger(:users, another_argument: 1) }
      end.to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#update_trigger" do
    it "records the updated trigger" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      migration = double("migration", update_trigger: nil)

      recorder.update_trigger(:users, version: 2)
      recorder.replay(migration)

      expect(migration).to have_received(:update_trigger).with(:users, version: 2)
    end

    it "reverts to update_trigger with the specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      migration = double("migration", update_trigger: nil)

      recorder.revert { recorder.update_trigger(:users, version: 2, revert_to_version: 1) }
      recorder.replay(migration)

      expect(migration).to have_received(:update_trigger).with(:users, version: 1)
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      expect do
        recorder.revert { recorder.update_trigger(:users, version: 42, another_argument: 1) }
      end.to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end
end
