require "fx/trigger"

module Fx
  module Adapters
    class Postgres
      # Fetches defined triggers from the postgres connection.
      # @api private
      class Triggers
        # The SQL query used by F(x) to retrieve the triggers considered
        # dumpable into `db/schema.rb`.
        TRIGGERS_WITH_DEFINITIONS_QUERY = <<~EOS.freeze
          SELECT
              pt.tgname AS name,
              pg_get_triggerdef(pt.oid) AS definition
          FROM pg_trigger pt
          JOIN pg_class pc
              ON (pc.oid = pt.tgrelid)
          JOIN pg_proc pp
              ON (pp.oid = pt.tgfoid)
          WHERE pt.tgname
          NOT ILIKE '%constraint%' AND pt.tgname NOT ILIKE 'pg%'
          ORDER BY pc.oid;
        EOS

        # Wraps #all as a static facade.
        #
        # @return [Array<Fx::Trigger>]
        def self.all(...)
          new(...).all
        end

        def initialize(connection)
          @connection = connection
        end

        # All of the triggers that this connection has defined.
        #
        # @return [Array<Fx::Trigger>]
        def all
          triggers_from_postgres.map { |trigger| to_fx_trigger(trigger) }
        end

        private

        attr_reader :connection

        def triggers_from_postgres
          connection.execute(TRIGGERS_WITH_DEFINITIONS_QUERY)
        end

        def to_fx_trigger(result)
          Fx::Trigger.new(result)
        end
      end
    end
  end
end
