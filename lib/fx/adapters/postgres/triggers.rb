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
        #
        # Every trigger on an extension-owned table is deferred to the
        # extension script: enabling the extension recreates the table and
        # its triggers, so dumping them breaks `db:schema:load` with
        # PG::DuplicateObject (issue #97). This matches pg_dump, which
        # does not emit triggers attached to extension member tables.
        # Triggers on ordinary tables that call extension-owned functions
        # still dump, since the extension will not recreate those.
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
          LEFT JOIN pg_depend pdt
              ON pdt.classid = 'pg_class'::regclass
              AND pdt.objid = pc.oid
              AND pdt.deptype = 'e'
          WHERE pn.nspname = ANY (current_schemas(false))
              AND pdt.objid IS NULL
              AND pt.tgname NOT ILIKE '%constraint%'
              AND pt.tgname NOT ILIKE 'pg%'
          ORDER BY pc.oid;
        SQL

        # Wraps #all as a static facade.
        #
        # @return [Array<Fx::Trigger>]
        def self.all(connection)
          Fx::Adapters::Postgres::QueryExecutor.call(
            connection: connection,
            query: TRIGGERS_WITH_DEFINITIONS_QUERY,
            model_class: Fx::Trigger
          )
        end
      end
    end
  end
end
