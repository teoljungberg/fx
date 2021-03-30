require "fx/aggregate"

module Fx
  module Adapters
    class Postgres
      # Fetches defined aggregates from the postgres connection.
      # @api private
      class Aggregates
        # The SQL query used by F(x) to retrieve the aggregates considered
        # dumpable into `db/schema.rb`.
        AGGREGATES_WITH_DEFINITIONS_QUERY = <<-EOS.freeze
          SELECT
              pp.proname AS name,
              pg_get_function_identity_arguments(pp.oid) AS arguments,
              pa.*,
              format_type(pa.aggtranstype, null) AS aggtranstype,
              format_type(pa.aggmtranstype, null) AS aggmtranstype
          FROM pg_proc pp
          JOIN pg_aggregate pa
              ON pa.aggfnoid = pp.oid
          JOIN pg_namespace pn
              ON pn.oid = pp.pronamespace
          LEFT JOIN pg_depend pd
              ON pd.objid = pp.oid AND pd.deptype = 'e'
          WHERE pn.nspname = 'public'
            AND pp.prokind = 'a'
            AND pd.objid IS NULL
          ORDER BY pp.oid;
        EOS

        # Wraps #all as a static facade.
        #
        # @return [Array<Fx::Aggregate>]
        def self.all(*args)
          new(*args).all
        end

        def initialize(connection)
          @connection = connection
        end

        # All of the aggregates that this connection has defined.
        #
        # @return [Array<Fx::Aggregate>]
        def all
          aggregates_from_postgres.map { |aggregate| to_fx_aggregate(aggregate) }
        end

        private

        attr_reader :connection

        def aggregates_from_postgres
          connection.execute(AGGREGATES_WITH_DEFINITIONS_QUERY)
        end

        def to_fx_aggregate(result)
          Fx::Aggregate.new(result)
        end
      end
    end
  end
end
