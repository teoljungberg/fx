require "fx/adapters/postgres/connection"
require "fx/adapters/postgres/functions"
require "fx/adapters/postgres/triggers"

module Fx
  # F(x) database adapters.
  #
  # F(x) ships with a Postgres adapter only but can be extended with
  # additional adapters. The {Fx::Adapters::Postgres} adapter provides the
  # interface.
  module Adapters
    # Creates an instance of the F(x) Postgres adapter.
    #
    # This is the default adapter for F(x). Configuring it via
    # {Fx.configure} is not required, but the example below shows how one
    # would explicitly set it.
    #
    # @param [#connection] connectable An object that returns the connection
    #   for F(x) to use. Defaults to `ActiveRecord::Base`.
    #
    # @example
    #  Fx.configure do |config|
    #    config.adapter = Fx::Adapters::Postgres.new
    #  end
    class Postgres
      # Creates an instance of the F(x) Postgres adapter.
      #
      # This is the default adapter for F(x). Configuring it via
      # {Fx.configure} is not required, but the example below shows how one
      # would explicitly set it.
      #
      # @param [#connection] connectable An object that returns the connection
      #   for F(x) to use. Defaults to `ActiveRecord::Base`.
      #
      # @example
      #  Fx.configure do |config|
      #    config.adapter = Fx::Adapters::Postgres.new
      #  end
      def initialize(connectable = ActiveRecord::Base)
        @connectable = connectable
      end

      # Returns an array of functions in the database.
      #
      # This collection of functions is used by the [Fx::SchemaDumper] to
      # populate the `schema.rb` file.
      #
      # @return [Array<Fx::Function>]
      def functions
        Fx::Adapters::Postgres::Functions.all(connection)
      end

      # Returns an array of triggers in the database.
      #
      # This collection of triggers is used by the [Fx::SchemaDumper] to
      # populate the `schema.rb` file.
      #
      # @return [Array<Fx::Trigger>]
      def triggers
        Fx::Adapters::Postgres::Triggers.all(connection)
      end

      # Creates a function in the database.
      #
      # This is typically called in a migration via
      # {Fx::Statements::Function#create_function}.
      #
      # @param sql_definition [String] The SQL schema for the function.
      #
      # @return [void]
      def create_function(sql_definition)
        execute(sql_definition)
      end

      # Creates a trigger in the database.
      #
      # This is typically called in a migration via
      # {Fx::Statements::Trigger#create_trigger}.
      #
      # @param sql_definition [String] The SQL schema for the trigger.
      #
      # @return [void]
      def create_trigger(sql_definition)
        execute(sql_definition)
      end

      # Updates a function in the database.
      #
      # This is typically called in a migration via
      # {Fx::Statements::Function#update_function}.
      #
      # @param name [String, Symbol] The name of the function.
      # @param sql_definition [String] The SQL schema for the function.
      # @param arguments [String] Optional function argument types for
      #   identifying overloaded functions (e.g. "integer, text"). This
      #   option is specific to the Postgres adapter.
      #
      # @return [void]
      def update_function(name, sql_definition, arguments: nil)
        drop_function(name, arguments: arguments)
        create_function(sql_definition)
      end

      # Updates a trigger in the database.
      #
      # The existing trigger is dropped and recreated using the supplied `on`
      # and `version` parameter.
      #
      # This is typically called in a migration via
      # {Fx::Statements::Function#update_trigger}.
      #
      # @param name [String, Symbol] The name of the trigger.
      # @param on [String, Symbol] The associated table for the trigger to update
      # @param sql_definition [String] The SQL schema for the trigger.
      #
      # @return [void]
      def update_trigger(name, on:, sql_definition:)
        drop_trigger(name, on: on)
        create_trigger(sql_definition)
      end

      # Drops the function from the database
      #
      # This is typically called in a migration via
      # {Fx::Statements::Function#drop_function}.
      #
      # @param name [String, Symbol] The name of the function to drop.
      # @param arguments [String] Optional function argument types for
      #   identifying overloaded functions (e.g. "integer, text"). When not
      #   provided, the argument types are looked up automatically from
      #   pg_proc. If multiple overloads exist, an {Fx::AmbiguousFunctionError}
      #   is raised. This option is specific to the Postgres adapter; custom
      #   adapters that do not accept it will raise an ArgumentError.
      #
      # @return [void]
      def drop_function(name, arguments: nil)
        arguments ||= function_arguments_for(name)

        if arguments
          execute("DROP FUNCTION #{name}(#{arguments});")
        else
          execute("DROP FUNCTION #{name};")
        end
      end

      # Drops the trigger from the database
      #
      # This is typically called in a migration via
      # {Fx::Statements::Trigger#drop_trigger}.
      #
      # @param name [String, Symbol] The name of the trigger to drop
      # @param on [String, Symbol] The associated table for the trigger to drop
      #
      # @return [void]
      def drop_trigger(name, on:)
        execute("DROP TRIGGER #{name} ON #{on};")
      end

      private

      # The SQL query used to look up a function's argument types from pg_proc.
      FUNCTION_ARGUMENTS_QUERY = <<~SQL.freeze
        SELECT pg_get_function_identity_arguments(pp.oid) AS arguments
        FROM pg_proc pp
        JOIN pg_namespace pn ON pn.oid = pp.pronamespace
        WHERE pp.proname = %{function_name}
          AND pp.prokind = 'f'
          AND %{schema_condition}
      SQL
      private_constant :FUNCTION_ARGUMENTS_QUERY

      attr_reader :connectable

      delegate :execute, to: :connection

      def function_arguments_for(name)
        name_str = name.to_s

        if (match = name_str.match(/\A"?([^"]+)"?\."?([^"]+)"?\z/))
          schema = match[1]
          function_name = match[2]
          schema_condition = "pn.nspname = #{connection.quote(schema)}"
        else
          function_name = name_str
          schema_condition = "pn.nspname = ANY(current_schemas(false))"
        end

        rows = connection.execute(
          FUNCTION_ARGUMENTS_QUERY % {
            function_name: connection.quote(function_name),
            schema_condition: schema_condition
          }
        ).to_a

        case rows.length
        when 0
          nil
        when 1
          rows.first["arguments"].presence
        else
          signatures = rows.map { |r| "#{name_str}(#{r["arguments"]})" }
          raise Fx::AmbiguousFunctionError, <<~MSG.chomp
            Multiple definitions for function "#{name_str}": #{signatures.join(", ")}.
            Specify which to drop: drop_function :#{name_str}, arguments: "<argument types>"
          MSG
        end
      end

      def connection
        Fx::Adapters::Postgres::Connection.new(connectable.connection)
      end
    end
  end
end
