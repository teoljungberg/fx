require "fx/function"
require "fx/adapters/postgres/query_executor"

module Fx
  module Adapters
    class Postgres
      # Fetches defined functions from the postgres connection.
      # @api private
      class Functions
        # The SQL query used by F(x) to retrieve the functions considered
        # dumpable into `db/schema.rb`.
        FUNCTIONS_WITH_DEFINITIONS_QUERY = <<~SQL.freeze
          SELECT
              pp.proname AS name,
              pg_get_functiondef(pp.oid) AS definition
          FROM pg_proc pp
          JOIN pg_namespace pn
              ON pn.oid = pp.pronamespace
          LEFT JOIN pg_depend pd
              ON pd.objid = pp.oid AND pd.deptype = 'e'
          LEFT JOIN pg_aggregate pa
              ON pa.aggfnoid = pp.oid
          WHERE pn.nspname = ANY (current_schemas(false))
              AND pd.objid IS NULL
              AND pa.aggfnoid IS NULL
          ORDER BY pp.oid;
        SQL

        # Wraps #all as a static facade.
        #
        # @return [Array<Fx::Function>]
        def self.all(connection)
          Fx::Adapters::Postgres::QueryExecutor.call(
            connection: connection,
            query: FUNCTIONS_WITH_DEFINITIONS_QUERY,
            model_class: Fx::Function
          )
        end
      end
    end
  end
end
