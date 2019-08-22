require "rails"

module Fx
  module SchemaDumper
    # @api private
    module Function
      def tables(stream)
        functions(stream) if Fx.configuration.define_functions_at_schema_beginning
        super
        functions(stream) unless Fx.configuration.define_functions_at_schema_beginning
      end

      def functions(stream)
        if dumpable_functions_in_database.any?
          stream.puts
        end

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
