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
      sorted_functions(Fx.database.functions).each do |function|
        stream.puts
        stream.puts(function.to_schema)
      end
    end

    def sorted_functions(functions)
      if (function_sorter = Fx.configuration.function_sorter)
        function_sorter.call(functions)
      else
        functions
      end
    end

    def triggers(stream)
      Fx.database.triggers.each do |trigger|
        stream.puts
        stream.puts(trigger.to_schema)
      end
    end
  end
end
