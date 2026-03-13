module Fx
  # F(x)'s configuration object.
  class Configuration
    # The F(x) database adapter instance to use when executing SQL.
    #
    # Defaults to an instance of {Fx::Adapters::Postgres}
    # @return [Fx::Adapters::Postgres] Fx adapter
    attr_accessor :database

    # Prioritizes the order in the schema.rb of functions before other
    # statements in order to make directly schema load work when using functions
    # in statements below, i.e.: default column values.
    #
    # Defaults to false
    # @return [Boolean] Boolean
    attr_accessor :dump_functions_at_beginning_of_schema

    # A callable that sorts functions before they are dumped to schema.rb.
    # Must respond to `.call(functions)` and return a sorted array of
    # {Fx::Function} objects.
    #
    # Defaults to nil (no sorting, preserves database order).
    # @return [#call, nil] Function sorter
    attr_accessor :function_sorter

    # A callable that sorts triggers before they are dumped to schema.rb.
    # Must respond to `.call(triggers)` and return a sorted array of
    # {Fx::Trigger} objects.
    #
    # Defaults to nil (no sorting, preserves database order).
    # @return [#call, nil] Trigger sorter
    attr_accessor :trigger_sorter

    def initialize
      @database = Fx::Adapters::Postgres.new
      @dump_functions_at_beginning_of_schema = false
      @function_sorter = nil
      @trigger_sorter = nil
    end
  end
end
