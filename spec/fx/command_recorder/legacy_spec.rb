require "spec_helper"

RSpec.describe Fx::CommandRecorder::Legacy do
  it "records keyword arguments as a trailing hash flagged as keywords" do
    recorder = build_recorder

    recorder.update_function(:test, version: 2)

    command, args = recorder.recorded
    expect(command).to eq(:update_function)
    expect(args).to eq([:test, {version: 2}])
    expect(Hash.ruby2_keywords_hash?(args.last)).to eq(true)
  end

  it "records commands without keyword arguments as positional arguments" do
    recorder = build_recorder

    recorder.create_function(:test)

    expect(recorder.recorded).to eq([:create_function, [:test]])
  end

  it "documents a positional options hash end to end" do
    recorder = build_recorder

    # Ruby 3: braces with parentheses mean the options hash travels as a
    # positional, non-keyword argument. Inversion keeps the recorded shape
    # and the drop inverse takes no version.
    recorder.create_function(:test, {version: 2})

    command, args = recorder.recorded
    expect(command).to eq(:create_function)
    expect(args).to eq([:test, {version: 2}])
    expect(Hash.ruby2_keywords_hash?(args.last)).to eq(false)

    inverse_command, inverse_args = recorder.invert_create_function(args)
    expect(inverse_command).to eq(:drop_function)
    expect(inverse_args).to eq([:test])
  end

  it "inverts a trailing hash flagged as keywords" do
    recorder = build_recorder
    args = [:test, Hash.ruby2_keywords_hash({version: 2, revert_to_version: 1})]

    command, inverse_args = recorder.invert_update_function(args)

    expect(command).to eq(:update_function)
    expect(inverse_args).to eq([:test, {version: 1}])
    expect(Hash.ruby2_keywords_hash?(inverse_args.last)).to eq(true)
  end

  def build_recorder
    Class.new do
      include Fx::CommandRecorder::Legacy

      attr_reader :recorded

      def record(*command)
        @recorded = command
      end
    end.new
  end
end
