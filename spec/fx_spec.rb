require "spec_helper"

RSpec.describe Fx do
  it "has a version number" do
    expect(Fx::VERSION).to be_present
  end

  it "loads fx into ActiveRecord" do
    expect(Fx.load).to eq(true)
    expect(ActiveRecord::Migration::CommandRecorder.ancestors.first)
      .to eq(Fx::CommandRecorder).or eq(Fx::CommandRecorder::Legacy)
    expect(ActiveRecord::ConnectionAdapters::AbstractAdapter).to include(Fx::Statements)
    expect(ActiveRecord::SchemaDumper).to include(Fx::SchemaDumper)
  end

  it "records and inverts fx commands through a plain CommandRecorder" do
    Fx.load

    recorder = ActiveRecord::Migration::CommandRecorder.new

    recorder.create_function :horses, version: 2
    expect(recorder.commands.first.first).to eq(:create_function)

    recorder.revert { recorder.create_function :horses, version: 2 }
    expect(recorder.commands.last.first).to eq(:drop_function)
  end

  it "loads the command recorder on Active Record 8.2" do
    command_recorder = stub_command_recorder
    stub_active_record_version("8.2.0.alpha")

    Fx.load

    expect(command_recorder).to include(Fx::CommandRecorder)
    expect(command_recorder).not_to include(Fx::CommandRecorder::Legacy)
  end

  it "loads the legacy command recorder before Active Record 8.2" do
    command_recorder = stub_command_recorder
    stub_active_record_version("8.1.1")

    Fx.load

    expect(command_recorder).to include(Fx::CommandRecorder::Legacy)
    expect(command_recorder).not_to include(Fx::CommandRecorder)
  end

  it "allows configuration" do
    adapter = double("Fx Adapter")

    Fx.configure do |config|
      config.database = adapter
      config.dump_functions_at_beginning_of_schema = true
    end

    expect(Fx.configuration.database).to eq(adapter)
    expect(Fx.configuration.dump_functions_at_beginning_of_schema).to eq(true)

    Fx.configuration = nil
  end

  def stub_command_recorder
    stub_const("ActiveRecord::Migration::CommandRecorder", Class.new)
  end

  def stub_active_record_version(version)
    allow(ActiveRecord).to receive(:gem_version).and_return(Gem::Version.new(version))
  end
end
