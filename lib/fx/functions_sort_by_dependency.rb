require "tsort"

module Fx
  class FunctionsSortByDependency
    include TSort

    def self.call(functions)
      new(functions).call
    end

    def initialize(functions)
      @functions = functions
      @stripped_definitions = {}
    end

    def call
      # Uses strongly_connected_components instead of tsort to tolerate
      # mutually recursive functions, which are valid in PostgreSQL.
      strongly_connected_components.flatten(FLATTEN_DEPTH)
    end

    private

    FLATTEN_DEPTH = 1
    private_constant :FLATTEN_DEPTH

    SINGLE_LINE_COMMENT = /--[^\n]*/
    private_constant :SINGLE_LINE_COMMENT

    BLOCK_COMMENT = %r{/\*.*?\*/}m
    private_constant :BLOCK_COMMENT

    STRING_LITERAL = /'(?:[^']|'')*'/
    private_constant :STRING_LITERAL

    attr_reader :functions

    def tsort_each_node(&block)
      functions.each(&block)
    end

    def tsort_each_child(function, &block)
      dependencies_of(function).each(&block)
    end

    def dependencies_of(function)
      definition = strip_non_code(function)

      functions
        .reject { |other| other == function }
        .select { |other| definition.match?(function_call_pattern(other.name)) }
    end

    def function_call_pattern(name)
      /(?<![a-zA-Z0-9_])#{Regexp.escape(name)}[ \t]*\(/
    end

    def strip_non_code(function)
      @stripped_definitions[function] ||= function.definition
        .gsub(STRING_LITERAL, "")
        .gsub(SINGLE_LINE_COMMENT, "")
        .gsub(BLOCK_COMMENT, "")
    end
  end
end
