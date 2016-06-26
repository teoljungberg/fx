require "rails"

module Fx
  module SchemaDumper
    module Trigger
      def tables(stream)
        super
        triggers(stream)
      end

      def triggers(stream)
        if dumpable_triggers_in_database.any?
          stream.puts
        end

        dumpable_triggers_in_database.each do |trigger|
          stream.puts(trigger.to_schema)
        end
      end

      private

      def dumpable_triggers_in_database
        @_dumpable_triggers_in_database ||= Fx.database.triggers
      end

      unless ActiveRecord::SchemaDumper.instance_methods(false).include?(:ignored?)
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
  :prepend,
  Fx::SchemaDumper::Trigger,
)
