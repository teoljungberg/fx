module Fx
  module SchemaDumper
    module Function
      extend ActiveSupport::Concern

      included { alias_method_chain :tables, :functions }

      def tables_with_functions(stream)
        tables_without_functions(stream)
        functions(stream)
      end

      def functions(stream)
        defined_functions.sort.
          reject { |function_name| ignored?(function_name) }.
          each { |function_name| function(function_name, stream) }
      end

      def function(name, stream)
        stream.puts(<<~DEFINITION)
          create_function :#{name}, <<~\SQL
        #{functions_with_definitions[name]}
          SQL
        DEFINITION
        stream
      end

      def defined_functions
        functions_with_definitions.keys
      end

      def functions_with_definitions
        @_functions_with_definitions ||= Hash[
          @connection.execute(
            Fx.database::FUNCTIONS_WITH_DEFINITIONS_QUERY,
            "SCHEMA",
          ).values,
        ]
      end

      unless ActiveRecord::SchemaDumper.
          instance_methods(false).
          include?(:ignored?)
        # This method will be present in Rails 4.2.0 and can be removed then.
        def ignored?(table_name)
          ["schema_migrations", ignore_tables].flatten.any? do |ignored|
            case ignored
            when String; remove_prefix_and_suffix(table_name) == ignored
            when Regexp; remove_prefix_and_suffix(table_name) =~ ignored
            else
              raise(
                StandardError,
                "ActiveRecord::SchemaDumper.ignore_tables accepts an array of String and / or Regexp values.",
              )
            end
          end
        end
      end
    end
  end
end

ActiveRecord::SchemaDumper.send(
  :include,
  Fx::SchemaDumper::Function,
)
