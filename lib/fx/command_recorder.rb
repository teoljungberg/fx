require "fx/command_recorder/inversion"

module Fx
  # @api private
  module CommandRecorder
    def create_function(*args, **kwargs, &block)
      record(:create_function, Fx::CommandRecorder.fold(args, kwargs), &block)
    end

    def drop_function(*args, **kwargs, &block)
      record(:drop_function, Fx::CommandRecorder.fold(args, kwargs), &block)
    end

    def update_function(*args, **kwargs, &block)
      record(:update_function, Fx::CommandRecorder.fold(args, kwargs), &block)
    end

    def invert_create_function(args)
      perform_inversion(:create_function, args)
    end

    def invert_drop_function(args)
      perform_inversion(:drop_function, args)
    end

    def invert_update_function(args)
      perform_inversion(:update_function, args)
    end

    def create_trigger(*args, **kwargs, &block)
      record(:create_trigger, Fx::CommandRecorder.fold(args, kwargs), &block)
    end

    def drop_trigger(*args, **kwargs, &block)
      record(:drop_trigger, Fx::CommandRecorder.fold(args, kwargs), &block)
    end

    def update_trigger(*args, **kwargs, &block)
      record(:update_trigger, Fx::CommandRecorder.fold(args, kwargs), &block)
    end

    def invert_create_trigger(args)
      perform_inversion(:create_trigger, args)
    end

    def invert_drop_trigger(args)
      perform_inversion(:drop_trigger, args)
    end

    def invert_update_trigger(args)
      perform_inversion(:update_trigger, args)
    end

    # Folds keyword arguments into a trailing hash flagged as keywords, so
    # `CommandRecorder#replay` passes them on as keywords.
    def self.fold(args, kwargs)
      if kwargs.empty?
        args
      else
        [*args, Hash.ruby2_keywords_hash(kwargs)]
      end
    end

    def self.split(args)
      if args.last.is_a?(Hash)
        [args[0...-1], args.last]
      else
        [args, {}]
      end
    end

    private

    def perform_inversion(command, args)
      inverse, inverse_args, inverse_kwargs = Fx::CommandRecorder::Inversion.invert(command, *Fx::CommandRecorder.split(args))

      [inverse, Fx::CommandRecorder.fold(inverse_args, inverse_kwargs)]
    end
  end
end
