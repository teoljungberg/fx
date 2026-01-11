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

      return unless dumpable_functions_in_database.any?

      stream.puts

      dumpable_functions_in_database.each_with_index do |function, index|
        stream.puts(function.to_schema)
        stream.puts unless index == dumpable_functions_in_database.size - 1
      end
    end

    def triggers(stream)
      dumpable_triggers_in_database = Fx.database.triggers

      return unless dumpable_triggers_in_database.any?

      stream.puts

      dumpable_triggers_in_database.each_with_index do |trigger, index|
        stream.puts(trigger.to_schema)
        stream.puts unless index == dumpable_triggers_in_database.size - 1
      end
    end
  end
end
