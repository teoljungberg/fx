module Fx
  # @api private
  class Function
    include Comparable

    attr_reader :name, :definition

    def initialize(row)
      @name = row.fetch("name")
      @definition = row.fetch("definition")
      @arguments = row.fetch("arguments", nil)
    end

    def <=>(other)
      signature <=> other.signature
    end

    def ==(other)
      signature == other.signature && definition == other.definition
    end

    def signature
      if @arguments.nil?
        name
      else
        "#{name}(#{@arguments})"
      end
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
