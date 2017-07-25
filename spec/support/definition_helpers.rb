module DefinitionHelpers
  def with_aggregate_definition(name:, sql_definition:, version: 1, &block)
    definition = Fx::Definition.new(
      name: name,
      version: version,
      type: "aggregate",
    )

    with_definition(
      definition: definition,
      sql_definition: sql_definition,
      block: block,
    )
  end

  def with_function_definition(name:, sql_definition:, version: 1, &block)
    definition = Fx::Definition.new(name: name, version: version)

    with_definition(
      definition: definition,
      sql_definition: sql_definition,
      block: block,
    )
  end

  def with_trigger_definition(name:, sql_definition:, version: 1, &block)
    definition = Fx::Definition.new(
      name: name,
      version: version,
      type: "trigger",
    )

    with_definition(
      definition: definition,
      sql_definition: sql_definition,
      block: block,
    )
  end

  def with_definition(definition:, sql_definition:, block:)
    FileUtils.mkdir_p(File.dirname(definition.full_path))
    File.open(definition.full_path, "w") { |f| f.write(sql_definition) }
    block.call
  ensure
    File.delete definition.full_path
  end
end

RSpec.configure do |config|
  config.include DefinitionHelpers
end
