module DefinitionHelpers
  def with_definition(name:, sql_definition:, version: 1)
    definition = Fx::Definition.new(name, version)
    FileUtils.mkdir_p(File.dirname(definition.full_path))
    File.open(definition.full_path, "w") { |f| f.write(sql_definition) }
    yield
  ensure
    File.delete definition.full_path
  end
end

RSpec.configure do |config|
  config.include DefinitionHelpers
end
