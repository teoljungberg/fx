module Fx
  # @api private
  module SchemaDumper
    def tables(stream)
      if Fx.configuration.dump_functions_at_beginning_of_schema
        functions(stream)
        super
      else
        super
        functions(stream)
      end

      triggers(stream)
    end

    private

    def functions(stream)
      dump_each(stream, Fx.database.functions)
    end

    def triggers(stream)
      dump_each(stream, Fx.database.triggers)
    end

    def dump_each(stream, definitions)
      definitions.each do |definition|
        stream.puts
        stream.puts(definition.to_schema)
      end
    end
  end
end
