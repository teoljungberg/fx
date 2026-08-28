module Fx
  module Adapters
    # Abstract base class for F(x) adapters.
    #
    # Subclasses must implement the public instance methods that F(x) calls
    # from migrations and the schema dumper. An adapter can be set through
    # {Fx.configure}:
    #
    #   Fx.configure do |config|
    #     config.database = MyAdapter.new
    #   end
    #
    # For database-specific customizations within an application, subclass the
    # concrete adapter (e.g. {Fx::Adapters::Postgres}) instead.
    class AbstractAdapter
      # Returns an array of functions in the database.
      #
      # This collection is used by {Fx::SchemaDumper} to populate `schema.rb`.
      #
      # @return [Array<Fx::Function>]
      def functions
        not_implemented(:functions)
      end

      # Returns an array of triggers in the database.
      #
      # This collection is used by {Fx::SchemaDumper} to populate `schema.rb`.
      #
      # @return [Array<Fx::Trigger>]
      def triggers
        not_implemented(:triggers)
      end

      # Creates a function in the database.
      #
      # This is typically called from a migration via
      # {Fx::Statements::Function#create_function}.
      #
      # @param sql_definition [String] The SQL schema for the function.
      # @return [void]
      def create_function(sql_definition)
        not_implemented(:create_function)
      end

      # Creates a trigger in the database.
      #
      # This is typically called from a migration via
      # {Fx::Statements::Trigger#create_trigger}.
      #
      # @param sql_definition [String] The SQL schema for the trigger.
      # @return [void]
      def create_trigger(sql_definition)
        not_implemented(:create_trigger)
      end

      # Updates a function in the database.
      #
      # This is typically called from a migration via
      # {Fx::Statements::Function#update_function}.
      #
      # @param name [String, Symbol] The name of the function.
      # @param sql_definition [String] The SQL schema for the function.
      # @return [void]
      def update_function(name, sql_definition)
        not_implemented(:update_function)
      end

      # Updates a trigger in the database.
      #
      # This is typically called from a migration via
      # {Fx::Statements::Trigger#update_trigger}.
      #
      # @param name [String, Symbol] The name of the trigger.
      # @param on [String, Symbol] The associated table for the trigger.
      # @param sql_definition [String] The SQL schema for the trigger.
      # @return [void]
      def update_trigger(name, on:, sql_definition:)
        not_implemented(:update_trigger)
      end

      # Drops the function from the database.
      #
      # This is typically called from a migration via
      # {Fx::Statements::Function#drop_function}.
      #
      # @param name [String, Symbol] The name of the function to drop.
      # @return [void]
      def drop_function(name)
        not_implemented(:drop_function)
      end

      # Drops the trigger from the database.
      #
      # This is typically called from a migration via
      # {Fx::Statements::Trigger#drop_trigger}.
      #
      # @param name [String, Symbol] The name of the trigger to drop.
      # @param on [String, Symbol] The associated table for the trigger.
      # @return [void]
      def drop_trigger(name, on:)
        not_implemented(:drop_trigger)
      end

      private

      def not_implemented(method_name)
        raise NotImplementedError, "#{method_name} must be implemented by #{self.class}"
      end
    end
  end
end
