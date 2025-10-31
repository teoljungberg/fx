require "fx/trigger"
require "fx/adapters/postgres/query_executor"

module Fx
  module Adapters
    class Postgres
      # Fetches defined triggers from the postgres connection.
      # @api private
      class Triggers
        # The SQL query used by F(x) to retrieve the triggers considered
        # dumpable into `db/schema.rb`.
        TRIGGERS_WITH_DEFINITIONS_QUERY = <<~SQL.freeze
          SELECT
              pt.tgname AS name,
              pg_get_triggerdef(pt.oid) AS definition
          FROM pg_trigger pt
          JOIN pg_class pc
              ON (pc.oid = pt.tgrelid)
          JOIN pg_proc pp
              ON (pp.oid = pt.tgfoid)
          JOIN pg_namespace pn
              ON pn.oid = pc.relnamespace
          WHERE pn.nspname = ANY (current_schemas(false))
              AND pt.tgname NOT ILIKE '%constraint%'
              AND pt.tgname NOT ILIKE 'pg%'
          ORDER BY pc.oid;
        SQL

        # Wraps #all as a static facade.
        #
        # @return [Array<Fx::Trigger>]
        def self.all(connection)
          QueryExecutor.call(
            connection: connection,
            query: TRIGGERS_WITH_DEFINITIONS_QUERY,
            model_class: Fx::Trigger
          )
        end
      end
    end
  end
end
