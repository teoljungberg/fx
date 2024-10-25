module Fx
  # F(x)'s configuration object.
  class Configuration
    # The F(x) database adapter instance to use when executing SQL.
    #
    # Defaults to an instance of {Fx::Adapters::Postgres}
    # @return Fx adapter
    attr_accessor :database

    # Prioritizes the order in the schema.rb of functions before other
    # statements in order to make directly schema load work when using functions
    # in statements below, i.e.: default column values.
    #
    # Defaults to false
    # @return Boolean
    attr_accessor :dump_functions_at_beginning_of_schema

    # Orders functions and triggers alphabetically in the schema dump.
    # When set to true, functions and triggers will appear in alphabetical
    # order within the schema.rb file.
    #
    # Defaults to false
    # @return Boolean
    attr_accessor :dump_functions_and_triggers_alphabetically

    def initialize
      @database = Fx::Adapters::Postgres.new
      @dump_functions_at_beginning_of_schema = false
      @dump_functions_and_triggers_alphabetically = false
    end
  end
end
