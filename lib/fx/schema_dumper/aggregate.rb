require "rails"

module Fx
  module SchemaDumper
    # @api private
    module Aggregate
      def tables(stream)
        super
        aggregates(stream)
      end

      def aggregates(stream)
        if dumpable_aggregates_in_database.any?
          stream.puts
        end

        dumpable_aggregates_in_database.each do |aggregate|
          stream.puts(aggregate.to_schema)
        end
      end

      private

      def dumpable_aggregates_in_database
        @_dumpable_aggregates_in_database ||= Fx.database.aggregates
      end
    end
  end
end
