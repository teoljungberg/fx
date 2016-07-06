module Fx
  # @api private
  class Trigger
    attr_reader :name, :definition
    delegate :<=>, to: :name

    def initialize(function_row)
      @name = function_row.fetch("name")
      @definition = function_row.fetch("definition")
    end

    def ==(other)
      name == other.name && definition == other.definition
    end

    def to_schema
      <<-SCHEMA.indent(4)
create_trigger :#{name}, sql_definition: <<-\SQL
#{definition.indent(2)}
SQL

      SCHEMA
    end
  end
end
