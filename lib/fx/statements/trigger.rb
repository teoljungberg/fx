module Fx
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
      # @param sql_definition [String] The SQL query for the function. An error
      #   will be raised if `sql_definition` and `version` are both set,
      #   as they are mutually exclusive.
      # @return The database response from executing the create statement.
      #
      # @example Create trigger from `db/triggers/uppercase_users_name_v01.sql`
      #   create_trigger(:uppercase_users_name, version: 1)
      #
      # @example Create trigger from provided SQL string
      #   create_trigger(:uppercase_users_name, sql_definition: <<-SQL)
      #     CREATE TRIGGER uppercase_users_name
      #         BEFORE INSERT ON users
      #         FOR EACH ROW
      #         EXECUTE PROCEDURE uppercase_users_name();
      #    SQL
      #
      # This method get called with some rails magick we can't control, so we're doing
      # something gross and c-styling their incoming args.
      def create_trigger(*args)
        name = args[0]
        version = args[1]&.[](:version)
        on = args[1]&.[](:on) || nil
        sql_definition = args[1]&.[](:sql_definition) || nil

        if version.present? && sql_definition.present?
          raise(
            ArgumentError,
            "sql_definition and version cannot both be set",
          )
        end

        if version.nil?
          version = 1
        end

        sql_definition = sql_definition.strip_heredoc if sql_definition
        sql_definition ||= Fx::Definition.new(
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
      def drop_trigger(name, args)
        on = args[:on]
        revert_to_version = args[:revert_to_version] || nil
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
      # @param sql_definition [String] The SQL query for the function. An error
      #   will be raised if `sql_definition` and `version` are both set,
      #   as they are mutually exclusive.
      # @param revert_to_version [Fixnum] The version number to rollback to on
      #   `rake db rollback`
      # @return The database response from executing the create statement.
      #
      # @example Update trigger to a given version
      #   update_trigger(
      #     :log_inserts,
      #     on: :users,
      #     version: 3,
      #     revert_to_version: 2,
      #   )
      #
      # @example Update trigger from provided SQL string
      #   update_trigger(:uppercase_users_name, sql_definition: <<-SQL)
      #     CREATE TRIGGER uppercase_users_name
      #         BEFORE INSERT ON users
      #         FOR EACH ROW
      #         EXECUTE PROCEDURE uppercase_users_name();
      #    SQL
      #
      def update_trigger(name, args)
        version = args[:version]
        on = args[:on]
        sql_definition = args[:sql_definition]
        revert_to_version = args[:revert_to_version]

        if version.nil? && sql_definition.nil?
          raise(
            ArgumentError,
            "version or sql_definition must be specified",
          )
        end

        if version.present? && sql_definition.present?
          raise(
            ArgumentError,
            "sql_definition and version cannot both be set",
          )
        end

        if on.nil?
          raise ArgumentError, "on is required"
        end

        sql_definition = sql_definition.strip_heredoc if sql_definition
        sql_definition ||= Fx::Definition.new(
          name: name,
          version: version,
          type: DEFINTION_TYPE,
        ).to_sql

        Fx.database.update_trigger(
          name,
          on: on,
          sql_definition: sql_definition,
        )
      end
    end
  end
end
