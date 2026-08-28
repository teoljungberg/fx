RSpec.shared_examples "an fx adapter" do
  it "is an AbstractAdapter" do
    expect(subject).to be_a(Fx::Adapters::AbstractAdapter)
  end

  it "implements all required adapter methods" do
    Fx::Adapters::AbstractAdapter::REQUIRED_METHODS.each do |method_name|
      expect(subject).to respond_to(method_name)
      expect(described_class.instance_method(method_name).owner).not_to eq(Fx::Adapters::AbstractAdapter)
    end
  end
end
