module FunctionDefinitionHelpers
  def with_function_definition(name:, definition:, version: 1)
    filename = ::Rails.root.join(
      "db",
      "functions",
      "#{name}_v#{version}.sql",
    )
    File.open(filename, "w") { |f| f.write(definition) }
    yield
  ensure
    File.delete filename
  end
end

RSpec.configure do |config|
  config.include FunctionDefinitionHelpers
end
