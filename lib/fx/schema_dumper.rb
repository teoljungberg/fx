module Fx
  # @api private
  module SchemaDumper
    def tables(stream)
      if Fx.configuration.dump_functions_at_beginning_of_schema
        functions(stream)
        empty_line(stream)
      end

      super

      unless Fx.configuration.dump_functions_at_beginning_of_schema
        functions(stream)
        empty_line(stream)
      end

      triggers(stream)
    end

    private

    def empty_line(stream)
      stream.puts if dumpable_functions_in_database.any?
    end

    def functions(stream)
      dumpable_functions_in_database.each do |function|
        stream.puts(function.to_schema)
      end
    end

    def triggers(stream)
      if dumpable_triggers_in_database.any?
        stream.puts
      end

      dumpable_triggers_in_database.each do |trigger|
        stream.puts(trigger.to_schema)
      end
    end

    def dumpable_functions_in_database
      @_dumpable_functions_in_database ||= Fx.database.functions
    end

    def dumpable_triggers_in_database
      @_dumpable_triggers_in_database ||= Fx.database.triggers
    end
  end
end
