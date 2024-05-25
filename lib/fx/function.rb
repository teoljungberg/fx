module Fx
  # @api private
  class Function
    include Comparable

    attr_reader :name, :definition
    delegate :<=>, to: :name

    def initialize(row)
      @name = row.fetch("name")
      @definition = row.fetch("definition")
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
