module Fx
  # @api private
  class Function
    include Comparable

    attr_reader :name, :arguments, :definition
    delegate :<=>, to: :name

    def initialize(function)
      @name = function.fetch("name")
      @arguments = function.fetch("arguments", [])
      @definition = function.fetch("definition")
    end

    def ==(other)
      name == other.name &&
        definition == other.definition &&
        arguments == other.arguments
    end

    def to_schema
      <<-SCHEMA.indent(2)
create_function :#{name}, sql_definition: <<-\SQL
#{definition.indent(4).rstrip}
SQL
      SCHEMA
    end
  end
end
