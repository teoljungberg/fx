require "spec_helper"

RSpec.describe Fx::CommandRecorder::LegacyInversion do
  describe ".invert" do
    it "inverts keyword arguments from a trailing hash flagged as keywords" do
      args = [:test, Hash.ruby2_keywords_hash({version: 2, revert_to_version: 1})]

      command, inverse_args = described_class.invert(:update_function, args)

      expect(command).to eq(:update_function)
      expect(inverse_args).to eq([:test, {version: 1}])
      expect(Hash.ruby2_keywords_hash?(inverse_args.last)).to eq(true)
    end

    it "inverts keyword arguments from a trailing hash not flagged as keywords" do
      args = [:test, {revert_to_version: 1}]

      command, inverse_args = described_class.invert(:drop_function, args)

      expect(command).to eq(:create_function)
      expect(inverse_args).to eq([:test, {version: 1}])
      expect(Hash.ruby2_keywords_hash?(inverse_args.last)).to eq(true)
    end
  end

  describe ".fold" do
    it "folds keyword arguments into a trailing hash flagged as keywords" do
      args = described_class.fold([:test], {version: 2})

      expect(args).to eq([:test, {version: 2}])
      expect(Hash.ruby2_keywords_hash?(args.last)).to eq(true)
    end

    it "leaves arguments alone without keyword arguments" do
      args = described_class.fold([:test], {})

      expect(args).to eq([:test])
    end
  end
end
