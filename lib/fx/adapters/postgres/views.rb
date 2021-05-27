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
            matviewname AS name,
            definition,
            true AS materialized
            FROM pg_catalog.pg_matviews
          WHERE schemaname = 'public' AND matviewowner = CURRENT_USER;
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
