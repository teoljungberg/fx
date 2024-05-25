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
        # https://www.postgresql.org/docs/9.6/sql-dropfunction.html
        # https://www.postgresql.org/docs/10/sql-dropfunction.html
        def support_drop_function_without_args
          pg_connection = undecorated_connection.raw_connection
          pg_connection.server_version >= 10_00_00
        end

        private

        def undecorated_connection
          __getobj__
        end
      end
    end
  end
end
