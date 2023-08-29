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
        return unless dumpable_functions_in_database.any?

        wrap_with_check_function_bodies(stream) do
          dumpable_functions_in_database.each do |function|
            stream.puts(function.to_schema)
          end
        end
      end

      private

      def dumpable_functions_in_database
        @_dumpable_functions_in_database ||= Fx.database.functions
      end

      def wrap_with_check_function_bodies(stream)
        should_wrap = [true, false].include?(Fx.configuration.check_function_bodies) && dumpable_functions_in_database.any?

        if should_wrap && Fx.configuration.check_function_bodies
          stream.puts("BEGIN;\nSET LOCAL check_function_bodies TO true;")
        elsif should_wrap && !Fx.configuration.check_function_bodies
          stream.puts("BEGIN;\nSET LOCAL check_function_bodies TO false;")
        end

        yield

        stream.puts("COMMIT;") if should_wrap
      end
    end
  end
end
