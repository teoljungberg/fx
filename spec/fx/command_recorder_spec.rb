require "spec_helper"

describe Fx::CommandRecorder do
  describe "#create_function" do
    it "records the created function" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.create_function :test

      expect(recorder.commands).to eq [
        [:create_function, [:test], nil],
      ]
    end

    it "reverts to drop_function" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.create_function :test

      expect(recorder.commands).to eq [
        [:create_function, [:test], nil],
      ]
    end

    it "reverts to drop_function" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.revert { recorder.create_function :test }

      expect(recorder.commands).to eq [[:drop_function, [:test]]]
    end
  end

  describe "#drop_function" do
    it "records the dropped function" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.drop_function :test

      expect(recorder.commands).to eq [[:drop_function, [:test], nil]]
    end

    it "reverts to create_function with specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, { revert_to_version: 3 }]
      revert_args = [:test, { version: 3 }]

      recorder.revert { recorder.drop_function(*args) }

      expect(recorder.commands).to eq [[:create_function, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, { another_argument: 1 }]

      expect { recorder.revert { recorder.drop_function(*args) } }.
        to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#update_function" do
    it "records the updated function" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, { version: 2 }]

      recorder.update_function(*args)

      expect(recorder.commands).to eq [[:update_function, args, nil]]
    end

    it "reverts to update_function with the specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, { version: 2, revert_to_version: 1 }]
      revert_args = [:test, { version: 1 }]

      recorder.revert { recorder.update_function(*args) }

      expect(recorder.commands).to eq [[:update_function, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, { version: 42, another_argument: 1 }]

      expect { recorder.revert { recorder.update_function(*args) } }.
        to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end
end
