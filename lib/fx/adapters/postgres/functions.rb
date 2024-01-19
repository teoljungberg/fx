require "fx/function"

module Fx
  module Adapters
    class Postgres
      # Fetches defined functions from the postgres connection.
      # @api private
      class Functions
        # The SQL query used by F(x) to retrieve the functions considered
        # dumpable into `db/schema.rb`.
        FUNCTIONS_WITH_DEFINITIONS_QUERY = <<-EOS.freeze
          SELECT
            pp.proname AS name,
            pn.nspname AS schema,
            pg_get_functiondef(pp.oid) AS definition,
            current_schema() AS current_schema
          FROM pg_proc pp
          JOIN pg_namespace pn
              ON pn.oid = pp.pronamespace
          LEFT JOIN pg_depend pd
              ON pd.objid = pp.oid AND pd.deptype = 'e'
          LEFT JOIN pg_aggregate pa
              ON pa.aggfnoid = pp.oid
          WHERE pn.nspname NOT IN ('pg_catalog', 'information_schema')
              AND pd.objid IS NULL
              AND pa.aggfnoid IS NULL
          ORDER BY pp.oid;
        EOS

        # Wraps #all as a static facade.
        #
        # @return [Array<Fx::Function>]
        def self.all(...)
          new(...).all
        end

        def initialize(connection)
          @connection = connection
        end

        # All of the functions that this connection has defined.
        #
        # @return [Array<Fx::Function>]
        def all
          functions_from_postgres.map do |function|
            to_fx_function(
              "name" => schema_aware_name(function),
              "definition" => schema_aware_definition(function)
            )
          end
        end

        private

        attr_reader :connection

        def functions_from_postgres
          connection.execute(FUNCTIONS_WITH_DEFINITIONS_QUERY)
        end

        def to_fx_function(result)
          Fx::Function.new(result)
        end

        def schema_aware_name(function)
          if function.fetch("schema") == function.fetch("current_schema")
            function.fetch("name")
          else
            "#{function.fetch("schema")}.#{function.fetch("name")}"
          end
        end

        def schema_aware_definition(function)
          if function.fetch("schema") == function.fetch("current_schema")
            function.fetch("definition").sub(
              /CREATE OR REPLACE FUNCTION #{function.fetch("schema")}\./,
              "CREATE OR REPLACE FUNCTION "
            )
          else
            function.fetch("definition")
          end
        end
      end
    end
  end
end
