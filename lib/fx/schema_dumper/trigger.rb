require "rails"

module Fx
  module SchemaDumper
    # @api private
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
    end
  end
end
