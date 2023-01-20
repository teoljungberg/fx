module Fx
  # @api private
  class Function
    include Comparable

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
      <<~SCHEMA.indent(2)
        create_function :#{name}, sql_definition: <<-'SQL'
        #{definition.indent(4).rstrip}
        SQL
      SCHEMA
    end
  end
end
