module Fx
  module Adapters
    class Postgres
      # Decorates an ActiveRecord connection with methods that help determine
      # the connections capabilities.
      #
      # Every attempt is made to use the versions of these methods defined by
      # Rails where they are available and public before falling back to our own
      # implementations for older Rails versions.
      #
      # @api private
      class Connection < SimpleDelegator
        # PostgreSQL version constants for feature support
        POSTGRES_VERSIONS = {
          # PostgreSQL 10.0 - introduced DROP FUNCTION without args
          # https://www.postgresql.org/docs/10/sql-dropfunction.html
          v10: 10_00_00
        }.freeze

        def support_drop_function_without_args
          server_version >= POSTGRES_VERSIONS[:v10]
        end

        private

        def server_version
          undecorated_connection.raw_connection.server_version
        end

        def undecorated_connection
          __getobj__
        end
      end
    end
  end
end
