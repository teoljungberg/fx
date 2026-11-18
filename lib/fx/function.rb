module Fx
  # A database function to dump into `schema.rb`.
  #
  # Part of the public adapter interface: adapters return instances of
  # this class from `functions`. The constructor takes a row (anything
  # responding to `#fetch`, such as a `Hash`) with `"name"` and
  # `"definition"` keys, and an optional `"arguments"` key holding the
  # function's identity arguments, used to disambiguate overloaded
  # functions.
  class Function
    include Comparable

    # @return [String] the name of the function
    attr_reader :name

    # @return [String] the SQL definition of the function
    attr_reader :definition

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
