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
        # PostgreSQL version constants for feature support.
        #
        # F(x) follows PostgreSQL's versioning policy, supporting all major
        # versions within their 5-year support window.
        # See: https://www.postgresql.org/support/versioning/
        #
        # Version format: XXYYZZ where XX=major, YY=minor, ZZ=patch
        # Example: 14_00_00 = PostgreSQL 14.0.0
        POSTGRES_VERSIONS = {
          v10: 10_00_00,  # DROP FUNCTION without args support
          v14: 14_00_00,  # Minimum supported version
          v15: 15_00_00,
          v16: 16_00_00,
          v17: 17_00_00,
          v18: 18_00_00   # Latest supported version
        }.freeze

        # The minimum PostgreSQL version officially supported by F(x).
        # Versions below this may work but are not tested or guaranteed.
        MINIMUM_SUPPORTED_VERSION = :v14
        private_constant :MINIMUM_SUPPORTED_VERSION

        def support_drop_function_without_args
          server_version >= POSTGRES_VERSIONS[:v10]
        end

        # Returns true if the connected PostgreSQL version is officially supported.
        #
        # @return [Boolean]
        def supported_postgres_version?
          server_version >= POSTGRES_VERSIONS[MINIMUM_SUPPORTED_VERSION]
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
