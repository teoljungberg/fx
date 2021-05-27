require "fx/view"

module Fx
  module Adapters
    class Postgres
      # Fetches defined views from the postgres connection.
      # @api private
      class Views
        # The SQL query used by F(x) to retrieve the views considered
        # dumpable into `db/schema.rb`.
        VIEWS_WITH_DEFINITIONS_QUERY = <<-EOS.freeze
          SELECT
            viewname AS name,
            definition,
            false AS materialized
          FROM pg_catalog.pg_views
          WHERE schemaname = 'public' AND viewowner = CURRENT_USER;
        EOS

        MATERIALIZED_VIEWS_WITH_DEFINITIONS_QUERY = <<-EOS.freeze
          SELECT
              name,
              CASE
                WHEN index_definition IS NULL THEN definition
                ELSE definition || E'\n\n' || index_definition
              END AS definition,
              true AS materialized
            FROM (SELECT
              matviewname AS name,
              definition,
              STRING_AGG(pg_indexes.indexdef || ';', E'\n') AS index_definition
            FROM pg_catalog.pg_matviews
            LEFT JOIN pg_indexes ON pg_indexes.tablename = pg_matviews.matviewname
            WHERE pg_matviews.schemaname = 'public' AND pg_matviews.matviewowner = CURRENT_USER
            GROUP BY pg_matviews.matviewname, pg_matviews.definition) materialized_views;
        EOS

        # Wraps #all as a static facade.
        #
        # @return [Array<Fx::View>]
        def self.all(*args)
          new(*args).all
        end

        def initialize(connection)
          @connection = connection
        end

        # All of the views that this connection has defined.
        #
        # @return [Array<Fx::View>]
        def all
          all_views.concat(all_materialized_views)
        end

        private

        attr_reader :connection

        def all_views
          views_from_postgres.map { |view| to_fx_view(view) }
        end

        def all_materialized_views
          materialized_views_from_postgres.map { |view| to_fx_view(view) }
        end

        def views_from_postgres
          connection.execute(VIEWS_WITH_DEFINITIONS_QUERY)
        end

        def materialized_views_from_postgres
          connection.execute(MATERIALIZED_VIEWS_WITH_DEFINITIONS_QUERY)
        end

        def to_fx_view(result)
          Fx::View.new(result)
        end
      end
    end
  end
end
