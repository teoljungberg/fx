module Fx
  # @api private
  class Function
    include Comparable

    attr_reader :name, :definition, :current_schema
    delegate :<=>, to: :name

    def initialize(row)
      @name = row.fetch("name")
      @definition = row.fetch("definition")
      @current_schema = row.fetch("current_schema")
    end

    def ==(other)
      name == other.name && definition == other.definition
    end

    def to_schema
      <<~SCHEMA.indent(2)
        create_function :#{name}, sql_definition: <<-'SQL'
          #{definition.indent(4).rstrip.gsub("#{current_schema}.", 'public.')}
        SQL
      SCHEMA
    end
  end
end
