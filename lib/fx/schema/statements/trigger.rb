module Fx
  module Schema
    module Statements
      # Methods that are made available in migrations for managing Fx triggers.
      module Trigger
        # @api private
        DEFINTION_TYPE = "trigger".freeze

        # Create a new database trigger.
        #
        # @param name [String, Symbol] The name of the database trigger.
        # @param version [Fixnum] The version number of the trigger, used to
        #   find the definition file in `db/triggers`. This defaults to `1` if
        #   not provided.
        # @param sql_definition [String] The SQL query for the trigger schema.
        #   If both `sql_defintiion` and `version` are provided,
        #   `sql_definition` takes prescedence.
        # @return The database response from executing the create statement.
        #
        # @example Create from `db/triggers/uppercase_users_name_v02.sql`
        #   create_trigger(:uppercase_users_name, version: 2)
        #
        # @example Create from provided SQL string
        #   create_trigger(:uppercase_users_name, sql_definition: <<-SQL)
        #     CREATE TRIGGER uppercase_users_name
        #         BEFORE INSERT ON users
        #         FOR EACH ROW
        #         EXECUTE PROCEDURE uppercase_users_name();
        #    SQL
        #
        def create_trigger(name, version: 1, on: nil, sql_definition: nil)
          if version.nil? && sql_definition.nil?
            raise(
              ArgumentError,
              "version or sql_definition must be specified",
            )
          end
          sql_definition = sql_definition ||
            Fx::Definition.new(
              name: name,
              version: version,
              type: DEFINTION_TYPE,
            ).to_sql

          Fx.database.create_trigger(sql_definition)
        end

        # Drop a database trigger by name.
        #
        # @param name [String, Symbol] The name of the database trigger.
        # @param on [String, Symbol] The name of the table the database trigger
        #   is associated with.
        # @param revert_to_version [Fixnum] Used to reverse the `drop_trigger`
        #   command on `rake db:rollback`. The provided version will be passed as
        #   the `version` argument to {#create_trigger}.
        # @return The database response from executing the drop statement.
        #
        # @example Drop a trigger, rolling back to version 3 on rollback
        #   drop_trigger(:log_inserts, on: :users, revert_to_version: 3)
        #
        def drop_trigger(name, on:, revert_to_version: nil)
          Fx.database.drop_trigger(name, on: on)
        end

        # Update a database trigger to a new version.
        #
        # The existing trigger is dropped and recreated using the supplied `on`
        # and `version` parameter.
        #
        # @param name [String, Symbol] The name of the database trigger.
        # @param version [Fixnum] The version number of the trigger.
        # @param on [String, Symbol] The name of the table the database trigger
        #   is associated with.
        # @param revert_to_version [Fixnum] The version number to rollback to on
        #   `rake db rollback`
        # @return The database response from executing the create statement.
        #
        # @example
        #   update_trigger(
        #     :log_inserts,
        #     on: :users,
        #     version: 3,
        #     revert_to_version: 2,
        #   )
        #
        def update_trigger(name, version: nil, on: nil, revert_to_version: nil)
          if version.nil?
            raise ArgumentError, "version is required"
          elsif on.nil?
            raise ArgumentError, "on is required"
          end

          drop_trigger(name, on: on)
          create_trigger(name, version: version)
        end
      end
    end
  end
end
