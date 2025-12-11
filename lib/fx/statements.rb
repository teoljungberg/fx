module Fx
  # @api private
  module Statements
    # Create a new database function.
    #
    # @param name [String, Symbol] The name of the database function.
    # @param version [Integer] The version number of the function, used to
    #   find the definition file in `db/functions`. This defaults to `1` if
    #   not provided.
    # @param sql_definition [String] The SQL query for the function schema.
    #   If both `sql_definition` and `version` are provided,
    #   `sql_definition` takes precedence.
    # @return [void] The database response from executing the create statement.
    #
    # @example Create from `db/functions/uppercase_users_name_v02.sql`
    #   create_function(:uppercase_users_name, version: 2)
    #
    # @example Create from provided SQL string
    #   create_function(:uppercase_users_name, sql_definition: <<~SQL)
    #     CREATE OR REPLACE FUNCTION uppercase_users_name()
    #     RETURNS trigger AS $$
    #     BEGIN
    #       NEW.upper_name = UPPER(NEW.name);
    #       RETURN NEW;
    #     END;
    #     $$ LANGUAGE plpgsql;
    #   SQL
    #
    def create_function(name, version: 1, sql_definition: nil, revert_to_version: nil)
      validate_version_or_sql_definition_present!(version, sql_definition)
      sql_definition = resolve_sql_definition(sql_definition, name, version, :function)

      Fx.database.create_function(sql_definition)
    end

    # Drop a database function by name.
    #
    # @param name [String, Symbol] The name of the database function.
    # @param revert_to_version [Integer] Used to reverse the `drop_function`
    #   command on `rake db:rollback`. The provided version will be passed as
    #   the `version` argument to {#create_function}.
    # @return [void] The database response from executing the drop statement.
    #
    # @example Drop a function, rolling back to version 2 on rollback
    #   drop_function(:uppercase_users_name, revert_to_version: 2)
    #
    def drop_function(name, revert_to_version: nil)
      Fx.database.drop_function(name)
    end

    # Update a database function.
    #
    # @param name [String, Symbol] The name of the database function.
    # @param version [Integer] The version number of the function, used to
    #   find the definition file in `db/functions`. This defaults to `1` if
    #   not provided.
    # @param sql_definition [String] The SQL query for the function schema.
    #   If both `sql_definition` and `version` are provided,
    #   `sql_definition` takes precedence.
    # @return [void] The database response from executing the create statement.
    #
    # @example Update function to a given version
    #   update_function(
    #     :uppercase_users_name,
    #     version: 3,
    #     revert_to_version: 2,
    #   )
    #
    # @example Update function from provided SQL string
    #   update_function(:uppercase_users_name, sql_definition: <<~SQL)
    #     CREATE OR REPLACE FUNCTION uppercase_users_name()
    #     RETURNS trigger AS $$
    #     BEGIN
    #       NEW.upper_name = UPPER(NEW.name);
    #       RETURN NEW;
    #     END;
    #     $$ LANGUAGE plpgsql;
    #   SQL
    #
    def update_function(name, version: nil, sql_definition: nil, revert_to_version: nil)
      validate_version_or_sql_definition_present!(version, sql_definition)

      sql_definition = resolve_sql_definition(sql_definition, name, version, :function)

      Fx.database.update_function(name, sql_definition)
    end

    # Create a new database trigger.
    #
    # @param name [String, Symbol] The name of the database trigger.
    # @param version [Integer] The version number of the trigger, used to
    #   find the definition file in `db/triggers`. This defaults to `1` if
    #   not provided.
    # @param sql_definition [String] The SQL query for the function. An error
    #   will be raised if `sql_definition` and `version` are both set,
    #   as they are mutually exclusive.
    # @return [void] The database response from executing the create statement.
    #
    # @example Create trigger from `db/triggers/uppercase_users_name_v01.sql`
    #   create_trigger(:uppercase_users_name, version: 1)
    #
    # @example Create trigger from provided SQL string
    #   create_trigger(:uppercase_users_name, sql_definition: <<~SQL)
    #     CREATE TRIGGER uppercase_users_name
    #         BEFORE INSERT ON users
    #         FOR EACH ROW
    #         EXECUTE FUNCTION uppercase_users_name();
    #    SQL
    #
    def create_trigger(name, version: nil, sql_definition: nil, on: nil, revert_to_version: nil)
      validate_version_and_sql_definition_exclusive!(version, sql_definition)

      version ||= 1

      sql_definition = resolve_sql_definition(sql_definition, name, version, :trigger)

      Fx.database.create_trigger(sql_definition)
    end

    # Drop a database trigger by name.
    #
    # @param name [String, Symbol] The name of the database trigger.
    # @param on [String, Symbol] The name of the table the database trigger
    #   is associated with.
    # @param revert_to_version [Integer] Used to reverse the `drop_trigger`
    #   command on `rake db:rollback`. The provided version will be passed as
    #   the `version` argument to {#create_trigger}.
    # @return [void] The database response from executing the drop statement.
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
    # @param version [Integer] The version number of the trigger.
    # @param on [String, Symbol] The name of the table the database trigger
    #   is associated with.
    # @param sql_definition [String] The SQL query for the function. An error
    #   will be raised if `sql_definition` and `version` are both set,
    #   as they are mutually exclusive.
    # @param revert_to_version [Integer] The version number to rollback to on
    #   `rake db rollback`
    # @return [void] The database response from executing the create statement.
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
    #   update_trigger(:uppercase_users_name, sql_definition: <<~SQL)
    #     CREATE TRIGGER uppercase_users_name
    #         BEFORE INSERT ON users
    #         FOR EACH ROW
    #         EXECUTE FUNCTION uppercase_users_name();
    #    SQL
    #
    def update_trigger(name, on:, version: nil, sql_definition: nil, revert_to_version: nil)
      validate_version_or_sql_definition_present!(version, sql_definition)
      validate_version_and_sql_definition_exclusive!(version, sql_definition)

      sql_definition = resolve_sql_definition(sql_definition, name, version, :trigger)

      Fx.database.update_trigger(
        name,
        on: on,
        sql_definition: sql_definition
      )
    end

    private

    VERSION_OR_SQL_DEFINITION_REQUIRED = "version or sql_definition must be specified".freeze
    private_constant :VERSION_OR_SQL_DEFINITION_REQUIRED

    VERSION_AND_SQL_DEFINITION_EXCLUSIVE = "sql_definition and version cannot both be set".freeze
    private_constant :VERSION_AND_SQL_DEFINITION_EXCLUSIVE

    def validate_version_or_sql_definition_present!(version, sql_definition)
      if version.nil? && sql_definition.nil?
        raise ArgumentError, VERSION_OR_SQL_DEFINITION_REQUIRED, caller
      end
    end

    def validate_version_and_sql_definition_exclusive!(version, sql_definition)
      if version.present? && sql_definition.present?
        raise ArgumentError, VERSION_AND_SQL_DEFINITION_EXCLUSIVE, caller
      end
    end

    def resolve_sql_definition(sql_definition, name, version, type)
      return sql_definition.strip_heredoc if sql_definition

      definition =
        case type
        when :function
          Fx::Definition.function(name: name, version: version)
        when :trigger
          Fx::Definition.trigger(name: name, version: version)
        else
          raise ArgumentError, "Unknown type: #{type}. Must be :function or :trigger", caller
        end

      definition.to_sql
    end
  end
end
