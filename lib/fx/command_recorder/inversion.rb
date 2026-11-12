module Fx
  module CommandRecorder
    # Inverts recorded fx migration commands, so `change` migrations can be
    # reverted. Holds no state across invocations and knows nothing about
    # how Active Record records commands.
    #
    # @api private
    class Inversion
      MESSAGE_IRREVERSIBLE = "`%s` is reversible only if given a `revert_to_version`".freeze
      private_constant :MESSAGE_IRREVERSIBLE

      MESSAGE_IRREVERSIBLE_WITHOUT_TABLE = "`create_trigger` is reversible only if given `on:`".freeze
      private_constant :MESSAGE_IRREVERSIBLE_WITHOUT_TABLE

      # @param command [Symbol] a recorded fx command, such as `:create_function`
      # @param args [Array] positional arguments of the recorded command
      # @param kwargs [Hash] keyword arguments of the recorded command
      # @return [Array(Symbol, Array, Hash)] the command that undoes it
      # @raise [ActiveRecord::IrreversibleMigration] when undoing a drop or
      #   update needs a `revert_to_version` that was not given, or undoing
      #   a `create_trigger` needs an `on:` that was not given
      # @raise [ArgumentError] when the command is not an fx command
      def self.invert(command, args, kwargs)
        new(command, args, kwargs).invert
      end

      def initialize(command, args, kwargs)
        @command = command
        @args = args
        @kwargs = kwargs
      end

      # @return [Array(Symbol, Array, Hash)] the command that undoes the
      #   recorded command
      def invert
        case command
        when :create_function then drop_function
        when :drop_function then revert_to_version(:create_function)
        when :update_function then revert_to_version(:update_function)
        when :create_trigger then drop_trigger
        when :drop_trigger then revert_to_version(:create_trigger)
        when :update_trigger then revert_to_version(:update_trigger)
        else raise ArgumentError, "`#{command}` is not an fx command"
        end
      end

      private

      attr_reader :command, :args, :kwargs

      def revert_to_version(inverse_command)
        revert_to_version = kwargs[:revert_to_version]

        if revert_to_version.nil?
          raise ActiveRecord::IrreversibleMigration, format(MESSAGE_IRREVERSIBLE, inverse_command)
        end

        inverse_kwargs = kwargs.except(:revert_to_version).merge(version: revert_to_version)

        [inverse_command, args, inverse_kwargs]
      end

      def drop_function
        [:drop_function, args, {}]
      end

      def drop_trigger
        if kwargs[:on].nil?
          raise ActiveRecord::IrreversibleMigration, MESSAGE_IRREVERSIBLE_WITHOUT_TABLE
        end

        inverse_kwargs = kwargs.slice(:on)

        [:drop_trigger, args, inverse_kwargs]
      end
    end
  end
end
