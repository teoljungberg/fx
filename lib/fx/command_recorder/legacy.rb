require "fx/command_recorder/inversion"

module Fx
  module CommandRecorder
    # Records fx migration commands for Active Record before 8.2, which
    # passes keyword arguments as a trailing hash flagged as keywords.
    #
    # This module is prepended into Active Record's command recorder, so it
    # contributes only the public command methods to that class; the
    # pre-8.2 argument-shape translation lives in private proc constants,
    # which prepending does not copy into the host.
    #
    # @api private
    module Legacy
      FOLD = ->(args, kwargs) do
        if kwargs.empty?
          args
        else
          [*args, Hash.ruby2_keywords_hash(kwargs)]
        end
      end
      private_constant :FOLD

      SPLIT = ->(args) do
        if args.last.is_a?(Hash)
          [args[0...-1], args.last]
        else
          [args, {}]
        end
      end
      private_constant :SPLIT

      INVERT = ->(command, args) do
        inverse, inverse_args, inverse_kwargs = Inversion.invert(command, *SPLIT.call(args))

        [inverse, FOLD.call(inverse_args, inverse_kwargs)]
      end
      private_constant :INVERT

      def create_function(*args, **kwargs, &block)
        record(:create_function, FOLD.call(args, kwargs), &block)
      end

      def drop_function(*args, **kwargs, &block)
        record(:drop_function, FOLD.call(args, kwargs), &block)
      end

      def update_function(*args, **kwargs, &block)
        record(:update_function, FOLD.call(args, kwargs), &block)
      end

      def invert_create_function(args)
        INVERT.call(:create_function, args)
      end

      def invert_drop_function(args)
        INVERT.call(:drop_function, args)
      end

      def invert_update_function(args)
        INVERT.call(:update_function, args)
      end

      def create_trigger(*args, **kwargs, &block)
        record(:create_trigger, FOLD.call(args, kwargs), &block)
      end

      def drop_trigger(*args, **kwargs, &block)
        record(:drop_trigger, FOLD.call(args, kwargs), &block)
      end

      def update_trigger(*args, **kwargs, &block)
        record(:update_trigger, FOLD.call(args, kwargs), &block)
      end

      def invert_create_trigger(args)
        INVERT.call(:create_trigger, args)
      end

      def invert_drop_trigger(args)
        INVERT.call(:drop_trigger, args)
      end

      def invert_update_trigger(args)
        INVERT.call(:update_trigger, args)
      end
    end
  end
end
