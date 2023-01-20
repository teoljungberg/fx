require "spec_helper"

module Fx::CommandRecorder
  describe Arguments do
    describe "#function" do
      it "returns the function name" do
        raw_args = [:spaceships, {foo: :bar}]
        args = Arguments.new(raw_args)

        expect(args.function).to eq :spaceships
      end
    end

    describe "#revert_to_version" do
      it "is the revert_to_version from the keyword arguments" do
        raw_args = [:spaceships, {revert_to_version: 42}]
        args = Arguments.new(raw_args)

        expect(args.revert_to_version).to eq 42
      end

      it "is nil if the revert_to_version was not supplied" do
        raw_args = [:spaceships, {foo: :bar}]
        args = Arguments.new(raw_args)

        expect(args.revert_to_version).to be nil
      end
    end

    describe "#invert_version" do
      it "returns object with version set to revert_to_version" do
        raw_args = [:meatballs, {version: 42, revert_to_version: 15}]

        inverted_args = Arguments.new(raw_args).invert_version

        expect(inverted_args.version).to eq 15
        expect(inverted_args.revert_to_version).to be nil
      end
    end
  end
end
