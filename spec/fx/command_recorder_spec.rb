require "spec_helper"

describe Fx::CommandRecorder, :db do
  describe "#create_function" do
    it "records the created function" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.create_function :test

      expect(recorder.commands).to eq [[:create_function, [:test], nil]]
    end

    it "reverts to drop_function" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.create_function :test

      expect(recorder.commands).to eq [[:create_function, [:test], nil]]
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
      args = [:test, {revert_to_version: 3}]
      revert_args = [:test, {version: 3}]

      recorder.revert { recorder.drop_function(*args) }

      expect(recorder.commands).to eq [[:create_function, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, {another_argument: 1}]

      expect { recorder.revert { recorder.drop_function(*args) } }
        .to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#update_function" do
    it "records the updated function" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, {version: 2}]

      recorder.update_function(*args)

      expect(recorder.commands).to eq [[:update_function, args, nil]]
    end

    it "reverts to update_function with the specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, {version: 2, revert_to_version: 1}]
      revert_args = [:test, {version: 1}]

      recorder.revert { recorder.update_function(*args) }

      expect(recorder.commands).to eq [[:update_function, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, {version: 42, another_argument: 1}]

      expect { recorder.revert { recorder.update_function(*args) } }
        .to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#create_trigger" do
    it "records the created trigger" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.create_trigger :greetings

      expect(recorder.commands).to eq [[:create_trigger, [:greetings], nil]]
    end

    it "reverts to drop_trigger" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.create_trigger :greetings

      expect(recorder.commands).to eq [
        [:create_trigger, [:greetings], nil]
      ]
    end

    it "reverts to drop_trigger" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.revert { recorder.create_trigger :greetings }

      expect(recorder.commands).to eq [[:drop_trigger, [:greetings]]]
    end
  end

  describe "#drop_trigger" do
    it "records the dropped trigger" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.drop_trigger :users

      expect(recorder.commands).to eq [[:drop_trigger, [:users], nil]]
    end

    it "reverts to create_trigger with specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:users, {revert_to_version: 3}]
      revert_args = [:users, {version: 3}]

      recorder.revert { recorder.drop_trigger(*args) }

      expect(recorder.commands).to eq [[:create_trigger, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:users, {another_argument: 1}]

      expect { recorder.revert { recorder.drop_trigger(*args) } }
        .to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#update_trigger" do
    it "records the updated trigger" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:users, {version: 2}]

      recorder.update_trigger(*args)

      expect(recorder.commands).to eq [[:update_trigger, args, nil]]
    end

    it "reverts to update_trigger with the specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:users, {version: 2, revert_to_version: 1}]
      revert_args = [:users, {version: 1}]

      recorder.revert { recorder.update_trigger(*args) }

      expect(recorder.commands).to eq [[:update_trigger, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:users, {version: 42, another_argument: 1}]

      expect { recorder.revert { recorder.update_trigger(*args) } }
        .to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#create_view" do
    it "records the created view" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.create_view :test

      expect(recorder.commands).to eq [[:create_view, [:test], nil]]
    end

    it "reverts to drop_view" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.create_view :test

      expect(recorder.commands).to eq [[:create_view, [:test], nil]]
    end

    it "reverts to drop_view" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.revert { recorder.create_view :test }

      expect(recorder.commands).to eq [[:drop_view, [:test]]]
    end
  end

  describe "#drop_view" do
    it "records the dropped view" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.drop_view :test

      expect(recorder.commands).to eq [[:drop_view, [:test], nil]]
    end

    it "reverts to create_view with specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, {revert_to_version: 3}]
      revert_args = [:test, {version: 3}]

      recorder.revert { recorder.drop_view(*args) }

      expect(recorder.commands).to eq [[:create_view, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, {another_argument: 1}]

      expect { recorder.revert { recorder.drop_view(*args) } }
        .to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#update_view" do
    it "records the updated view" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, {version: 2}]

      recorder.update_view(*args)

      expect(recorder.commands).to eq [[:update_view, args, nil]]
    end

    it "reverts to update_view with the specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, {version: 2, revert_to_version: 1}]
      revert_args = [:test, {version: 1}]

      recorder.revert { recorder.update_view(*args) }

      expect(recorder.commands).to eq [[:update_view, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, {version: 42, another_argument: 1}]

      expect { recorder.revert { recorder.update_view(*args) } }
        .to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end
end
