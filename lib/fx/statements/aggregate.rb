require "rails"

module Fx
  module Statements
    # Methods that are made available in migrations for managing Fx aggregates.
    module Aggregate
      # @api private
      DEFINITION_TYPE = "aggregate".freeze

      # Create a new database aggregate.
      #
      # @param name [String, Symbol] The name of the database aggregate.
      # @param version [Fixnum] The version number of the aggregate, used to
      #   find the definition file in `db/aggregates`. This defaults to `1` if
      #   not provided.
      # @param sql_definition [String] The SQL query for the aggregate schema.
      #   If both `sql_definition` and `version` are provided,
      #   `sql_definition` takes prescedence.
      # @return The database response from executing the create statement.
      #
      # @example Create from `db/aggregates/median_v2.sql`
      #   create_aggregate(:median, version: 2)
      #
      # @example Create from provided SQL string
      #   create_aggregate(:median, sql_definition: <<-SQL)
      #     CREATE AGGREGATE median(NUMERIC)(
      #       SFUNC = array_append,
      #       STYPE = NUMERIC[],
      #       FINALFUNC = array_median,
      #       INITCOND = '{}'
      #     )
      #   SQL
      #
      def create_aggregate(name, version: 1, sql_definition: nil)
        if version.nil? && sql_definition.nil?
          raise(
            ArgumentError,
            "version or sql_definition must be specified",
          )
        end

        sql_definition ||= Fx::Definition.new(
          name: name,
          version: version,
          type: DEFINITION_TYPE,
        ).to_sql

        Fx.database.create_aggregate(sql_definition)
      end

      # Drop a database aggregate by name.
      #
      # @param name [String, Symbol] The name of the database aggregate.
      # @param revert_to_version [Fixnum] Used to reverse the `drop_aggregate`
      #   command on `rake db:rollback`. The provided version will be passed as
      #   the `version` argument to {#create_aggregate}.
      # @return The database response from executing the drop statement.
      #
      # @example Drop a aggregate, rolling back to version 2 on rollback
      #   drop_aggregate(:median, revert_to_version: 2)
      #
      def drop_aggregate(name, revert_to_version: nil)
        Fx.database.drop_aggregate(name)
      end

      # Update a database aggregate.
      #
      # @param name [String, Symbol] The name of the database aggregate.
      # @param version [Fixnum] The version number of the aggregate, used to
      #   find the definition file in `db/aggregates`. This defaults to `1` if
      #   not provided.
      # @param sql_definition [String] The SQL query for the aggregate schema.
      #   If both `sql_definition` and `version` are provided,
      #   `sql_definition` takes prescedence.
      # @return The database response from executing the create statement.
      #
      # @example Update aggregate to a given version
      #   update_aggregate(
      #     :median,
      #     version: 3,
      #     revert_to_version: 2,
      #   )
      #
      # @example Update aggregate from provided SQL string
      #   update_aggregate(:median, sql_definition: <<-SQL)
      #     CREATE AGGREGATE median(NUMERIC)(
      #       SFUNC = array_append,
      #       STYPE = NUMERIC[],
      #       FINALFUNC = array_median,
      #       INITCOND = '{}'
      #     )
      #   SQL
      #
      def update_aggregate(name, version: nil, sql_definition: nil, revert_to_version: nil)
        if version.nil? && sql_definition.nil?
          raise(
            ArgumentError,
            "version or sql_definition must be specified",
          )
        end

        sql_definition ||= Fx::Definition.new(
          name: name,
          version: version,
          type: DEFINITION_TYPE
        ).to_sql

        Fx.database.update_aggregate(name, sql_definition)
      end
    end
  end
end
