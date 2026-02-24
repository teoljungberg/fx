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
      strongly_connected_components.flatten(SINGLE_LEVEL)
    end

    private

    SINGLE_LEVEL = 1
    private_constant :SINGLE_LEVEL

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
      /\b#{Regexp.escape(name)}[ \t]*\(/i
    end

    def strip_non_code(function)
      @stripped_definitions[function] ||= function.definition
        .gsub(SINGLE_LINE_COMMENT, "")
        .gsub(BLOCK_COMMENT, "")
        .gsub(STRING_LITERAL, "")
    end
  end
end
