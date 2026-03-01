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
        # All supported PostgreSQL versions (14+) support DROP FUNCTION
        # without argument lists.
        # https://www.postgresql.org/docs/10/sql-dropfunction.html
        def support_drop_function_without_args
          true
        end
      end
    end
  end
end
