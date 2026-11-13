require "spec_helper"
require "generators"

RSpec.describe Fx::Generators do
  it "is a module" do
    expect(described_class).to be_a(Module)
  end
end
