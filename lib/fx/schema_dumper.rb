module Fx
  # @api private
  module SchemaDumper
    def tables(stream)
      if Fx.configuration.dump_functions_at_beginning_of_schema
        functions(stream)
      end

      super

      unless Fx.configuration.dump_functions_at_beginning_of_schema
        functions(stream)
      end

      triggers(stream)
    end

    private

    def functions(stream)
      dumpable_functions_in_database = Fx.database.functions

      dumpable_functions_in_database.each do |function|
        stream.puts(function.to_schema)
      end

      stream.puts if dumpable_functions_in_database.any?
    end

    def triggers(stream)
      dumpable_triggers_in_database = Fx.database.triggers

      if dumpable_triggers_in_database.any?
        stream.puts
      end

      dumpable_triggers_in_database.each do |trigger|
        stream.puts(trigger.to_schema)
      end
    end
  end
end
