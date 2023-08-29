require "rails"

module Fx
  module SchemaDumper
    # @api private
    module Function
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
      end

      def empty_line(stream)
        stream.puts if dumpable_functions_in_database.any?
      end

      def functions(stream)
        dumpable_functions_in_database.each do |function|
          stream.puts(function.to_schema)
        end
      end

      private

      def dumpable_functions_in_database
        @_dumpable_functions_in_database ||= Fx.database.functions
      end
    end
  end
end
