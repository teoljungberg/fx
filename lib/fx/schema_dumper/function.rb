require "rails"

module Fx
  module SchemaDumper
    # @api private
    module Function
      def tables(stream)
        dump_functions(stream, dumpable_functions_at_beginning)

        if Fx.configuration.dump_functions_at_beginning_of_schema
          dump_functions(stream, dumpable_functions_excluded)
        end

        super

        unless Fx.configuration.dump_functions_at_beginning_of_schema
          dump_functions(stream, dumpable_functions_excluded)
        end

        dump_functions(stream, dumpable_functions_at_end)
      end

      def dump_functions(stream, functions)
        functions.each do |function|
          stream.puts(function.to_schema)
        end

        stream.puts if functions.any?
      end

      private

      def dumpable_functions_at_beginning
        @_dumpable_functions_at_beginning ||= dumpable_functions_in_database.select do |function|
          function.name.in? Fx.configuration.functions_to_dump_at_beginning_of_schema
        end
      end

      def dumpable_functions_at_end
        @_dumpable_functions_at_end ||= dumpable_functions_in_database.select do |function|
          function.name.in? Fx.configuration.functions_to_dump_at_end_of_schema
        end
      end

      def dumpable_functions_excluded
        @_dumpable_functions_excluded ||= dumpable_functions_in_database.reject do |func|
          func.name.in? (Fx.configuration.functions_to_dump_at_beginning_of_schema | Fx.configuration.functions_to_dump_at_end_of_schema)
        end
      end

      def dumpable_functions_in_database
        @_dumpable_functions_in_database ||= Fx.database.functions
      end
    end
  end
end
