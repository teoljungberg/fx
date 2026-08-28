RSpec.shared_examples "an fx adapter" do
  it "is an AbstractAdapter" do
    expect(subject).to be_a(Fx::Adapters::AbstractAdapter)
  end

  it "implements all required adapter methods" do
    required_methods = %i[
      functions
      triggers
      create_function
      create_trigger
      update_function
      update_trigger
      drop_function
      drop_trigger
    ]

    required_methods.each do |method_name|
      expect(subject).to respond_to(method_name)
      expect(described_class.instance_method(method_name).owner).not_to eq(Fx::Adapters::AbstractAdapter)
    end
  end
end
