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
              pg_get_functiondef(pp.oid) AS definition
          FROM pg_proc pp
          JOIN pg_namespace pn
              ON pn.oid = pp.pronamespace
          LEFT JOIN pg_depend pd
              ON pd.objid = pp.oid AND pd.deptype = 'e'
          WHERE pn.nspname = 'public' AND pd.objid IS NULL
          ORDER BY pp.oid;
        EOS

        CREATE_FUNCTION_COMMAND = 'CREATE OR REPLACE FUNCTION'

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
          connection.execute(FUNCTIONS_WITH_DEFINITIONS_QUERY)
        end

        def to_fx_function(result)
          function = Fx::Function.new(result)
          remove_public_schema_name_from_definition!(function)
          function
        end

        def remove_public_schema_name_from_definition!(function)
          function.definition.sub! "#{CREATE_FUNCTION_COMMAND} public.", "#{CREATE_FUNCTION_COMMAND} "
        end
      end
    end
  end
end
