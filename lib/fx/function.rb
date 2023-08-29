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
        #{definition_with_check_function_bodies(definition).indent(4).rstrip}
        SQL
      SCHEMA
    end

    private

    def definition_with_check_function_bodies(definition)
      should_wrap = [true, false].include?(Fx.configuration.check_function_bodies)
      return definition unless should_wrap

      output = []
      output << "BEGIN;\n" + "SET LOCAL check_function_bodies TO #{Fx.configuration.check_function_bodies};\n".indent(4)
      output << definition.indent(4).rstrip + ";"
      output << "COMMIT;"
      output.join("\n")
    end
  end
end
