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

      return if dumpable_functions_in_database.empty?

      dumpable_functions_in_database.each_with_index do |function, index|
        stream.puts
        stream.puts(function.to_schema)
      end
    end

    def triggers(stream)
      dumpable_triggers_in_database = Fx.database.triggers

      return if dumpable_triggers_in_database.empty?

      dumpable_triggers_in_database.each_with_index do |trigger, index|
        stream.puts
        stream.puts(trigger.to_schema)
      end
    end
  end
end
