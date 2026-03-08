require "spec_helper"

RSpec.describe Fx::CommandRecorder, :db do
  describe "#create_function" do
    it "records the created function" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.create_function :add

      expect(recorder.commands).to eq([[:create_function, [:add], nil]])
    end

    it "reverts to drop_function" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.revert { recorder.create_function :add }

      expect(recorder.commands).to eq([[:drop_function, [:add]]])
    end
  end

  describe "#drop_function" do
    it "records the dropped function" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.drop_function :add

      expect(recorder.commands).to eq([[:drop_function, [:add], nil]])
    end

    it "reverts to create_function with specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:add, {revert_to_version: 3}]
      revert_args = [:add, {version: 3}]

      recorder.revert { recorder.drop_function(*args) }

      expect(recorder.commands).to eq([[:create_function, revert_args]])
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:add, {another_argument: 1}]

      expect do
        recorder.revert { recorder.drop_function(*args) }
      end.to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#update_function" do
    it "records the updated function" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:add, {version: 2}]

      recorder.update_function(*args)

      expect(recorder.commands).to eq([[:update_function, args, nil]])
    end

    it "reverts to update_function with the specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:add, {version: 2, revert_to_version: 1}]
      revert_args = [:add, {version: 1}]

      recorder.revert { recorder.update_function(*args) }

      expect(recorder.commands).to eq([[:update_function, revert_args]])
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:add, {version: 42, another_argument: 1}]

      expect do
        recorder.revert { recorder.update_function(*args) }
      end.to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#create_trigger" do
    it "records the created trigger" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.create_trigger :set_upper_name

      expect(recorder.commands).to eq([[:create_trigger, [:set_upper_name], nil]])
    end

    it "reverts to drop_trigger" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.revert { recorder.create_trigger :set_upper_name }

      expect(recorder.commands).to eq([[:drop_trigger, [:set_upper_name]]])
    end
  end

  describe "#drop_trigger" do
    it "records the dropped trigger" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.drop_trigger :set_upper_name

      expect(recorder.commands).to eq([[:drop_trigger, [:set_upper_name], nil]])
    end

    it "reverts to create_trigger with specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:set_upper_name, {revert_to_version: 3}]
      revert_args = [:set_upper_name, {version: 3}]

      recorder.revert { recorder.drop_trigger(*args) }

      expect(recorder.commands).to eq([[:create_trigger, revert_args]])
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:set_upper_name, {another_argument: 1}]

      expect do
        recorder.revert { recorder.drop_trigger(*args) }
      end.to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#update_trigger" do
    it "records the updated trigger" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:set_upper_name, {version: 2}]

      recorder.update_trigger(*args)

      expect(recorder.commands).to eq([[:update_trigger, args, nil]])
    end

    it "reverts to update_trigger with the specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:set_upper_name, {version: 2, revert_to_version: 1}]
      revert_args = [:set_upper_name, {version: 1}]

      recorder.revert { recorder.update_trigger(*args) }

      expect(recorder.commands).to eq([[:update_trigger, revert_args]])
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:set_upper_name, {version: 42, another_argument: 1}]

      expect do
        recorder.revert { recorder.update_trigger(*args) }
      end.to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end
end
