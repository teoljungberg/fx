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
            definition
          FROM pg_catalog.pg_views
          WHERE schemaname = 'public' AND viewowner = CURRENT_USER;
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
          views_from_postgres.map { |view| to_fx_view(view) }
        end

        private

        attr_reader :connection

        def views_from_postgres
          connection.execute(VIEWS_WITH_DEFINITIONS_QUERY)
        end

        def to_fx_view(result)
          Fx::View.new(result)
        end
      end
    end
  end
end
