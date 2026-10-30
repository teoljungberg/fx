require "fx/command_recorder/legacy_inversion"

module Fx
  module CommandRecorder
    # Records fx migration commands for Active Record before 8.2, which
    # passes keyword arguments as a trailing hash flagged as keywords.
    #
    # @api private
    module Legacy
      def create_function(*args, **kwargs, &block)
        record(:create_function, Fx::CommandRecorder::LegacyInversion.fold(args, kwargs), &block)
      end

      def drop_function(*args, **kwargs, &block)
        record(:drop_function, Fx::CommandRecorder::LegacyInversion.fold(args, kwargs), &block)
      end

      def update_function(*args, **kwargs, &block)
        record(:update_function, Fx::CommandRecorder::LegacyInversion.fold(args, kwargs), &block)
      end

      def invert_create_function(args)
        Fx::CommandRecorder::LegacyInversion.invert(:create_function, args)
      end

      def invert_drop_function(args)
        Fx::CommandRecorder::LegacyInversion.invert(:drop_function, args)
      end

      def invert_update_function(args)
        Fx::CommandRecorder::LegacyInversion.invert(:update_function, args)
      end

      def create_trigger(*args, **kwargs, &block)
        record(:create_trigger, Fx::CommandRecorder::LegacyInversion.fold(args, kwargs), &block)
      end

      def drop_trigger(*args, **kwargs, &block)
        record(:drop_trigger, Fx::CommandRecorder::LegacyInversion.fold(args, kwargs), &block)
      end

      def update_trigger(*args, **kwargs, &block)
        record(:update_trigger, Fx::CommandRecorder::LegacyInversion.fold(args, kwargs), &block)
      end

      def invert_create_trigger(args)
        Fx::CommandRecorder::LegacyInversion.invert(:create_trigger, args)
      end

      def invert_drop_trigger(args)
        Fx::CommandRecorder::LegacyInversion.invert(:drop_trigger, args)
      end

      def invert_update_trigger(args)
        Fx::CommandRecorder::LegacyInversion.invert(:update_trigger, args)
      end
    end
  end
end
