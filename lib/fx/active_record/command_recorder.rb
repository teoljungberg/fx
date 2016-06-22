require "fx/active_record/command_recorder/arguments"

module Fx
  module ActiveRecord
    module CommandRecorder
      def create_function(*args)
        record(:create_function, args)
      end

      def drop_function(*args)
        record(:drop_function, args)
      end

      def update_function(*args)
        record(:update_function, args)
      end

      def invert_create_function(args)
        [:drop_function, args]
      end

      def invert_drop_function(args)
        perform_inversion(:create_function, args)
      end

      def invert_update_function(args)
        perform_inversion(:update_function, args)
      end

      private

      def perform_inversion(method, args)
        arguments = Arguments.new(args)

        if arguments.revert_to_version.nil?
          message = "`#{method}` is reversible only if given a `revert_to_version`"
          raise ::ActiveRecord::IrreversibleMigration, message
        end

        [method, arguments.invert_version.to_a]
      end
    end
  end
end

ActiveRecord::Migration::CommandRecorder.send(
 :include,
  Fx::ActiveRecord::CommandRecorder,
)
