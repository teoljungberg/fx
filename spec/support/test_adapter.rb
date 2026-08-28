module Fx
  # A minimal, in-memory adapter used to verify that F(x) works with any
  # plain Ruby object implementing the adapter interface.
  class TestAdapter < Fx::Adapters::AbstractAdapter
    attr_reader :created_functions, :created_triggers
    attr_reader :updated_functions, :updated_triggers
    attr_reader :dropped_functions, :dropped_triggers
    attr_writer :functions, :triggers

    def initialize
      @created_functions = []
      @created_triggers = []
      @updated_functions = []
      @updated_triggers = []
      @dropped_functions = []
      @dropped_triggers = []
      @functions = []
      @triggers = []
    end

    attr_reader :functions

    attr_reader :triggers

    def create_function(sql_definition)
      @created_functions << sql_definition
    end

    def create_trigger(sql_definition)
      @created_triggers << sql_definition
    end

    def update_function(name, sql_definition)
      @updated_functions << [name, sql_definition]
    end

    def update_trigger(name, on:, sql_definition:)
      @updated_triggers << [name, on, sql_definition]
    end

    def drop_function(name)
      @dropped_functions << name
    end

    def drop_trigger(name, on:)
      @dropped_triggers << [name, on]
    end
  end
end
