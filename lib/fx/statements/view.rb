require "rails"

module Fx
  module Statements
    # Methods that are made available in migrations for managing Fx views.
    module View
      # @api private
      DEFINTION_TYPE = "view".freeze

      # Create a new database view.
      #
      # @param name [String, Symbol] The name of the database view.
      # @param version [Fixnum] The version number of the view, used to
      #   find the definition file in `db/views`. This defaults to `1` if
      #   not provided.
      # @param sql_definition [String] The SQL query for the view schema.
      #   If both `sql_defintion` and `version` are provided,
      #   `sql_definition` takes prescedence.
      # @return The database response from executing the create statement.
      #
      # @example Create from `db/views/active_users_v02.sql`
      #   create_view(:active_users, version: 2)
      #
      # @example Create from provided SQL string
      #   create_view(:active_users, sql_definition: <<-SQL)
      #     CREATE VIEW active_users AS
      #     SELECT * users WHERE active = true;
      #   SQL
      #
      def create_view(name, options = {})
        version = options.fetch(:version, 1)
        sql_definition = options[:sql_definition]

        if version.nil? && sql_definition.nil?
          raise(
            ArgumentError,
            "version or sql_definition must be specified"
          )
        end
        sql_definition = sql_definition.strip_heredoc if sql_definition
        sql_definition ||= Fx::Definition.new(
          name: name,
          version: version,
          type: DEFINTION_TYPE
        ).to_sql

        Fx.database.create_view(sql_definition)
      end

      # Drop a database view by name.
      #
      # @param name [String, Symbol] The name of the database view.
      # @param revert_to_version [Fixnum] Used to reverse the `drop_view`
      #   command on `rake db:rollback`. The provided version will be passed as
      #   the `version` argument to {#create_view}.
      # @param materialized [Boolean] defines if the view is materialized or not.
      # @return The database response from executing the drop statement.
      #
      # @example Drop a view, rolling back to version 2 on rollback
      #   drop_view(:active_users, revert_to_version: 2)
      #
      def drop_view(name, options = {})
        materialized = options.fetch(:materialized, false)

        Fx.database.drop_view(name, materialized: materialized)
      end

      # Update a database view.
      #
      # @param name [String, Symbol] The name of the database view.
      # @param version [Fixnum] The version number of the view, used to
      #   find the definition file in `db/views`. This defaults to `1` if
      #   not provided.
      # @param sql_definition [String] The SQL query for the view schema.
      #   If both `sql_defintion` and `version` are provided,
      #   `sql_definition` takes prescedence.
      # @param materialized [Boolean] defines if the view is materialized or not.
      # @return The database response from executing the create statement.
      #
      # @example Update view to a given version
      #   update_view(
      #     :active_users,
      #     version: 3,
      #     revert_to_version: 2,
      #   )
      #
      # @example Update view from provided SQL string
      #   update_view(:active_users, sql_definition: <<-SQL)
      #     DROP VIEW IF EXISTS active_users;
      #     CREATE VIEW active_users AS
      #     SELECT * users WHERE active = true;
      #   SQL
      #
      def update_view(name, options = {})
        version = options.fetch(:version, 1)
        sql_definition = options[:sql_definition]
        materialized = options.fetch(:materialized, false)

        if version.nil? && sql_definition.nil?
          raise(
            ArgumentError,
            "version or sql_definition must be specified"
          )
        end

        sql_definition = sql_definition.strip_heredoc if sql_definition
        sql_definition ||= Fx::Definition.new(
          name: name,
          version: version,
          type: DEFINTION_TYPE
        ).to_sql

        Fx.database.update_view(name, sql_definition, materialized: materialized)
      end
    end
  end
end
