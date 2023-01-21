require "ammeter/init"

RSpec.configure do |config|
  config.before(:each, :generator) do
    fake_rails_root = File.expand_path("../../../tmp/dummy", __FILE__)
    allow(Rails).to receive(:root).and_return(Pathname.new(fake_rails_root))

    destination fake_rails_root
    prepare_destination
  end
end
