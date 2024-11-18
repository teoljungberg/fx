module Fx
  # @api private
  class Trigger
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
      definition = self.definition.gsub('public.', '')
      function_name = definition.split('FUNCTION ')[-1].split(".")[-1]
      definition.gsub!(function_name, "public.#{function_name}")
      <<-SCHEMA
        create_trigger :#{name}, sql_definition: <<-\SQL
          #{definition}
        SQL
      SCHEMA
    end
  end
end
