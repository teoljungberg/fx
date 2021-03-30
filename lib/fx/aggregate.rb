require "active_support/core_ext/hash/except"

module Fx
  # @api private
  class Aggregate
    include Comparable

    attr_reader :name, :arguments, :definition
    delegate :<=>, to: :name

    def initialize(aggregate_row)
      @name = aggregate_row.fetch("name")
      @arguments = aggregate_row.fetch("arguments", "")
      @definition = aggregate_row.except("name", "arguments")
    end

    def ==(other)
      other.is_a?(self.class) &&
        name == other.name &&
        arguments == other.arguments &&
        definition == other.definition
    end

    def to_schema
      <<-SCHEMA
  create_aggregate :#{name}, sql_definition: <<-\SQL
      CREATE OR REPLACE AGGREGATE #{name}(#{arguments})(
          #{options_for_create_statement.join(",\n").indent(10).lstrip}
      );
  SQL
      SCHEMA
    end

    private

    Field = Struct.new(:option, :type)

    # Maps pg_aggregate columns to their definition field and type.
    FIELDS = {
      "aggtransfn"     => Field.new("SFUNC", "raw"),
      "aggtranstype"   => Field.new("STYPE", "raw"),
      "aggtransspace"  => Field.new("SSPACE", "int"),
      "aggfinalfn"     => Field.new("FINALFUNC", "raw"),
      "aggfinalextra"  => Field.new("FINALFUNC_EXTRA", "bool"),
      "agginitval"     => Field.new("INITCOND", "string"),
    }.freeze

    def options_for_create_statement
      FIELDS.map do |key, field|
        value = format_value(field.type, @definition[key])
        next if !value

        if value == true
          field.option
        else
          "#{field.option} = #{value}"
        end
      end.compact
    end

    def format_value(type, value)
      return if value.nil?
      return if value == "-"

      case type
      when "bool"
        return value == "t"
      when "int"
        return if value.to_i == 0
      when "string"
        return "'#{value}'"
      end

      return value
    end
  end
end
