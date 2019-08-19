require "fx/function"

module Fx
  module Adapters
    class Postgres
      # Fetches defined functions from the postgres connection.
      # @api private
      class Functions
        # The SQL query used by F(x) to retrieve the functions considered
        # dumpable into `db/schema.rb`.
        PG_11_FUNCTIONS_WITH_DEFINITIONS_QUERY = <<-SQL.squish.freeze
          SELECT
            pp.proname,
            pg_get_functiondef(pp.oid)
          FROM pg_proc pp
          JOIN pg_namespace pn
            ON pn.oid = pp.pronamespace
          LEFT JOIN pg_depend pd
            ON pd.objid = pp.oid AND pd.deptype = 'e'
          WHERE
            pn.nspname = 'public' AND
            pd.objid IS NULL AND
            pp.prokind != 'a'
          ORDER BY pp.oid
        SQL

        PG_10_FUNCTIONS_WITH_DEFINITIONS_QUERY = <<-SQL.squish.freeze
          SELECT
            pp.proname,
            pg_get_functiondef(pp.oid)
          FROM pg_proc pp
          JOIN pg_namespace pn
            ON pn.oid = pp.pronamespace
          LEFT JOIN pg_depend pd
            ON pd.objid = pp.oid AND pd.deptype = 'e'
          WHERE
            pn.nspname = 'public' AND
            pd.objid IS NULL AND
            pp.proisagg = 'f'
          ORDER BY pp.oid
        SQL

        # Wraps #all as a static facade.
        #
        # @return [Array<Fx::Function>]
        def self.all(*args)
          new(*args).all
        end

        def initialize(connection)
          @connection = connection
        end

        # All of the functions that this connection has defined.
        #
        # @return [Array<Fx::Function>]
        def all
          functions_from_postgres.map { |function| to_fx_function(function) }
        end

        private

        attr_reader :connection

        def functions_from_postgres
          connection.execute(functions_with_definitions_query)
        end

        def functions_with_definitions_query
          if connection.raw_connection.server_version >= 11_00_00
            PG_11_FUNCTIONS_WITH_DEFINITIONS_QUERY
          else
            PG_10_FUNCTIONS_WITH_DEFINITIONS_QUERY
          end
        end

        def to_fx_function(result)
          Fx::Function.new(result)
        end
      end
    end
  end
end
