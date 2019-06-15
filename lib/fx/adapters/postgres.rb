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
      
      # The SQL query used by F(x) to retrieve the function name 
      # with its signature.
      FUNCTION_NAMES_WITH_THEIR_SIGNATURE = <<-EOS.freeze
          SELECT
              pp.proname AS name,
              CONCAT(pp.proname, '(', pg_get_function_identity_arguments(pp.oid), ')') AS signature
          FROM pg_proc pp
          JOIN pg_namespace pn
              ON pn.oid = pp.pronamespace
          LEFT JOIN pg_depend pd
              ON pd.objid = pp.oid AND pd.deptype = 'e'
          WHERE pn.nspname = 'public' AND pd.objid IS NULL;
        EOS


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
        Functions.all(connection)
      end

      # Returns an array of triggers in the database.
      #
      # This collection of triggers is used by the [Fx::SchemaDumper] to
      # populate the `schema.rb` file.
      #
      # @return [Array<Fx::Trigger>]
      def triggers
        Triggers.all(connection)
      end

      # Creates a function in the database.
      #
      # This is typically called in a migration via
      # {Fx::Statements::Function#create_function}.
      #
      # @param sql_definition The SQL schema for the function.
      #
      # @return [void]
      def create_function(sql_definition)
        execute sql_definition
      end

      # Creates a trigger in the database.
      #
      # This is typically called in a migration via
      # {Fx::Statements::Trigger#create_trigger}.
      #
      # @param sql_definition The SQL schema for the trigger.
      #
      # @return [void]
      def create_trigger(sql_definition)
        execute sql_definition
      end

      # Updates a function in the database.
      #
      # This is typically called in a migration via
      # {Fx::Statements::Function#update_function}.
      #
      # @param name The name of the function.
      # @param sql_definition The SQL schema for the function.
      #
      # @return [void]
      def update_function(name, sql_definition)
        drop_function(name)
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
      # @param name The name of the trigger.
      # @param on The associated table for the trigger to drop
      # @param sql_definition The SQL schema for the function.
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
      # @param name The name of the function to drop
      #
      # @return [void]
      def drop_function(name)
        if support_drop_function_without_args
          execute "DROP FUNCTION #{name};"
        else
          signature = function_signature_by_name name
          execute "DROP FUNCTION #{signature};"
        end
      end

      # Drops the trigger from the database
      #
      # This is typically called in a migration via
      # {Fx::Statements::Trigger#drop_trigger}.
      #
      # @param name The name of the trigger to drop
      # @param on The associated table for the trigger to drop
      #
      # @return [void]
      def drop_trigger(name, on:)
        execute "DROP TRIGGER #{name} ON #{on};"
      end

      private

      attr_reader :connectable

      delegate :execute, to: :connection

      def connection
        Connection.new(connectable.connection)
      end

      def support_drop_function_without_args
        # https://www.postgresql.org/docs/9.6/sql-dropfunction.html
        # https://www.postgresql.org/docs/10/sql-dropfunction.html

        PG.connect.server_version >= 10_00_00
      end

      def function_signature_by_name(name)
        connection.execute(FUNCTION_NAMES_WITH_THEIR_SIGNATURE).find { |tuple| tuple['name'] == name.to_s }['signature']
      end
    end
  end
end
