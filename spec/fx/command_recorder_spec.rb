require "spec_helper"

describe Fx::CommandRecorder, :db do
  describe "#create_aggregate" do
    it "records the created aggregate" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.create_aggregate :test

      expect(recorder.commands).to eq [[:create_aggregate, [:test], nil]]
    end

    it "reverts to drop_aggregate" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.create_aggregate :test

      expect(recorder.commands).to eq [[:create_aggregate, [:test], nil]]
    end

    it "reverts to drop_aggregate" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.revert { recorder.create_aggregate :test }

      expect(recorder.commands).to eq [[:drop_aggregate, [:test]]]
    end
  end

  describe "#drop_aggregate" do
    it "records the dropped aggregate" do
      recorder = ActiveRecord::Migration::CommandRecorder.new

      recorder.drop_aggregate :test

      expect(recorder.commands).to eq [[:drop_aggregate, [:test], nil]]
    end

    it "reverts to create_aggregate with specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, { revert_to_version: 3 }]
      revert_args = [:test, { version: 3 }]

      recorder.revert { recorder.drop_aggregate(*args) }

      expect(recorder.commands).to eq [[:create_aggregate, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, { another_argument: 1 }]

      expect { recorder.revert { recorder.drop_aggregate(*args) } }.
        to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#update_aggregate" do
    it "records the updated aggregate" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, { version: 2 }]

      recorder.update_aggregate(*args)

      expect(recorder.commands).to eq [[:update_aggregate, args, nil]]
    end

    it "reverts to update_aggregate with the specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, { version: 2, revert_to_version: 1 }]
      revert_args = [:test, { version: 1 }]

      recorder.revert { recorder.update_aggregate(*args) }

      expect(recorder.commands).to eq [[:update_aggregate, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:test, { version: 42, another_argument: 1 }]

      expect { recorder.revert { recorder.update_aggregate(*args) } }.
        to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

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
        [:create_trigger, [:greetings], nil],
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
      args = [:users, { revert_to_version: 3 }]
      revert_args = [:users, { version: 3 }]

      recorder.revert { recorder.drop_trigger(*args) }

      expect(recorder.commands).to eq [[:create_trigger, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:users, { another_argument: 1 }]

      expect { recorder.revert { recorder.drop_trigger(*args) } }.
        to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  describe "#update_trigger" do
    it "records the updated trigger" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:users, { version: 2 }]

      recorder.update_trigger(*args)

      expect(recorder.commands).to eq [[:update_trigger, args, nil]]
    end

    it "reverts to update_trigger with the specified revert_to_version" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:users, { version: 2, revert_to_version: 1 }]
      revert_args = [:users, { version: 1 }]

      recorder.revert { recorder.update_trigger(*args) }

      expect(recorder.commands).to eq [[:update_trigger, revert_args]]
    end

    it "raises when reverting without revert_to_version set" do
      recorder = ActiveRecord::Migration::CommandRecorder.new
      args = [:users, { version: 42, another_argument: 1 }]

      expect { recorder.revert { recorder.update_trigger(*args) } }.
        to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end
end
