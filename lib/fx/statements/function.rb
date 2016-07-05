require "rails"

module Fx
  module Statements
    # Methods that are made available in migrations for managing Fx functions.
    module Function
      # Create a new database function.
      #
      # @param name [String, Symbol] The name of the database function.
      # @param version [Fixnum] The version number of the function, used to
      #   find the definition file in `db/functions`. This defaults to `1` if
      #   not provided.
      # @param sql_definition [String] The SQL query for the function schema.
      #   If both `sql_defintion` and `version` are provided,
      #   `sql_definition` takes prescedence.
      # @return The database response from executing the create statement.
      #
      # @example Create from `db/functions/uppercase_users_name_v02.sql`
      #   create_function(:uppercase_users_name, version: 2)
      #
      # @example Create from provided SQL string
      #   create_function(:uppercase_users_name, sql_definition: <<-SQL)
      #     CREATE OR REPLACE FUNCTION uppercase_users_name()
      #     RETURNS trigger AS $$
      #     BEGIN
      #       NEW.upper_name = UPPER(NEW.name);
      #       RETURN NEW;
      #     END;
      #     $$ LANGUAGE plpgsql;
      #   SQL
      #
      def create_function(name, version: 1, sql_definition: nil)
        if version.nil? && sql_definition.nil?
          raise(
            ArgumentError,
            "version or sql_definition must be specified",
          )
        end
        sql_definition = sql_definition ||
          Fx::Definition.new(name: name, version: version).to_sql

        Fx.database.create_function(sql_definition)
      end

      # Drop a database function by name.
      #
      # @param name [String, Symbol] The name of the database function.
      # @param revert_to_version [Fixnum] Used to reverse the `drop_function`
      #   command on `rake db:rollback`. The provided version will be passed as
      #   the `version` argument to {#create_function}.
      # @return The database response from executing the drop statement.
      #
      # @example Drop a function, rolling back to version 3 on rollback
      #   drop_function(:uppercase_users_name, on: :users, revert_to_version: 3)
      #
      def drop_function(name, revert_to_version: nil)
        Fx.database.drop_function(name)
      end

      # Update a database function to a new version.
      #
      # The existing function is dropped and recreated using the supplied
      # `version` parameter.
      #
      # @param name [String, Symbol] The name of the database function.
      # @param version [Fixnum] The version number of the function.
      # @param revert_to_version [Fixnum] The version number to rollback to on
      #   `rake db rollback`.
      # @return The database response from executing the create statement.
      #
      # @example
      #   update_function(
      #     :uppercase_users_name,
      #     version: 3,
      #     revert_to_version: 2,
      #   )
      #
      def update_function(name, version: nil, revert_to_version: nil)
        if version.nil?
          raise ArgumentError, "version is required"
        end

        sql_definition = Fx::Definition.new(
          name: name,
          version: version,
        ).to_sql

        Fx.database.update_function(name, sql_definition)
      end
    end
  end
end
