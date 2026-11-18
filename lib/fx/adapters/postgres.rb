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
    # The default F(x) adapter, and F(x)'s extension point.
    #
    # The public methods of this class are the stable interface adapters
    # and adapter subclasses rely on: {#functions} and {#triggers}, used
    # by the schema dumper, and {#create_function}, {#drop_function},
    # {#update_function}, {#create_trigger}, {#drop_trigger}, and
    # {#update_trigger}, called by the migration statements. `functions`
    # and `triggers` return {Fx::Function} and {Fx::Trigger} instances.
    # Subclass this adapter to customize what F(x) dumps, or write an
    # adapter of your own responding to the same methods, and assign it
    # via {Fx::Configuration#database}.
    #
    # @example
    #  Fx.configure do |config|
    #    config.database = Fx::Adapters::Postgres.new
    #  end
    class Postgres
      # Creates an instance of the F(x) Postgres adapter.
      #
      # @param [#connection] connectable An object that returns the connection
      #   for F(x) to use. Defaults to `ActiveRecord::Base`.
      def initialize(connectable = ActiveRecord::Base)
        @connectable = connectable
      end

      # Returns an array of functions in the database.
      #
      # Part of the public adapter interface: the {Fx::SchemaDumper}
      # populates `schema.rb` from this collection.
      #
      # @return [Array<Fx::Function>]
      def functions
        Fx::Adapters::Postgres::Functions.all(connection)
      end

      # Returns an array of triggers in the database.
      #
      # Part of the public adapter interface: the {Fx::SchemaDumper}
      # populates `schema.rb` from this collection.
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
      # @param name [String, Symbol] The name of the function to drop
      #
      # @return [void]
      def drop_function(name)
        execute("DROP FUNCTION #{name};")
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

      attr_reader :connectable

      delegate :execute, to: :connection

      def connection
        Fx::Adapters::Postgres::Connection.new(connectable.connection)
      end
    end
  end
end
