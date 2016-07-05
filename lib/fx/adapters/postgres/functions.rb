require "fx/function"

module Fx
  module Adapters
    class Postgres
      # Fetches defined functions from the postgres connection.
      # @api private
      class Functions
        # The SQL query used by F(x) to retrieve the functions considered
        # dumpable into `db/schema.rb`.
        FUNCTIONS_WITH_DEFINITIONS_QUERY = <<~SQL
          SELECT
              pp.proname AS name,
              pg_get_functiondef(pp.oid) AS definition
          FROM pg_proc pp
          INNER JOIN pg_namespace pn
              ON (pn.oid = pp.pronamespace)
          INNER JOIN pg_language pl
              ON (pl.oid = pp.prolang)
          WHERE pl.lanname NOT IN ('c','internal')
              AND pn.nspname NOT LIKE 'pg_%'
              AND pn.nspname <> 'information_schema'
        SQL

        # Wraps #all as a static facade.
        #
        # @return [Array<Fx::Function>]
        def self.all(*args)
          new(*args).all
        end

        def initialize(connectable = ActiveRecord::Base.connection)
          @connectable = connectable
        end

        # All of the functions that this connection has defined.
        #
        # @return [Array<Fx::Function>]
        def all
          functions_from_postgres.map { |function| to_fx_function(function) }
        end

        private

        attr_reader :connectable

        def functions_from_postgres
          connectable.execute(FUNCTIONS_WITH_DEFINITIONS_QUERY)
        end

        def to_fx_function(result)
          Fx::Function.new(result)
        end
      end
    end
  end
end
