module Fx
  module CommandRecorder
    # Inverts recorded fx migration commands, so `change` migrations can be
    # reverted. Holds no state and knows nothing about how Active Record
    # records commands.
    #
    # @api private
    module Inversion
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
        case command
        when :create_function then drop_function(args)
        when :drop_function then revert_to_version(:create_function, args, kwargs)
        when :update_function then revert_to_version(:update_function, args, kwargs)
        when :create_trigger then drop_trigger(args, kwargs)
        when :drop_trigger then revert_to_version(:create_trigger, args, kwargs)
        when :update_trigger then revert_to_version(:update_trigger, args, kwargs)
        else raise ArgumentError, "`#{command}` is not an fx command"
        end
      end

      def self.revert_to_version(command, args, kwargs)
        revert_to_version = kwargs[:revert_to_version]

        if revert_to_version.nil?
          raise ActiveRecord::IrreversibleMigration, format(MESSAGE_IRREVERSIBLE, command)
        end

        inverse_kwargs = kwargs.except(:revert_to_version).merge(version: revert_to_version)

        [command, args, inverse_kwargs]
      end
      private_class_method :revert_to_version

      def self.drop_function(args)
        [:drop_function, args, {}]
      end
      private_class_method :drop_function

      def self.drop_trigger(args, kwargs)
        if kwargs[:on].nil?
          raise ActiveRecord::IrreversibleMigration, MESSAGE_IRREVERSIBLE_WITHOUT_TABLE
        end

        [:drop_trigger, args, kwargs.slice(:on)]
      end
      private_class_method :drop_trigger
    end
  end
end
