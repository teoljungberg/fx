# Implements only the methods documented as the public adapter interface,
# so the specs using it pin that set: anything core calls beyond it fails.
class RecordingAdapter
  attr_writer :functions, :triggers
  attr_reader :statements

  def initialize
    @functions = []
    @triggers = []
    @statements = []
  end

  attr_reader :functions

  attr_reader :triggers

  def create_function(sql_definition)
    statements << [:create_function, sql_definition]
  end

  def drop_function(name)
    statements << [:drop_function, name]
  end

  def update_function(name, sql_definition)
    statements << [:update_function, name, sql_definition]
  end

  def create_trigger(sql_definition)
    statements << [:create_trigger, sql_definition]
  end

  def drop_trigger(name, on:)
    statements << [:drop_trigger, name, on]
  end

  def update_trigger(name, on:, sql_definition:)
    statements << [:update_trigger, name, on, sql_definition]
  end
end
