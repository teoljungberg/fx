require "ammeter/init"
require "ammeter/rspec/generator/example"
require "ammeter/rspec/generator/matchers"

RSpec.configure do |config|
  config.before(:example, :generator) do
    destination File.expand_path("../../../tmp", __FILE__)
    prepare_destination
  end
end
