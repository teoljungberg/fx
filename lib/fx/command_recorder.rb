require "fx/command_recorder/inversion"
require "fx/command_recorder/legacy"

module Fx
  # Records fx migration commands so `change` migrations can be reverted.
  # Active Record 8.2+ passes positional and keyword arguments separately;
  # {Fx::CommandRecorder::Legacy} covers earlier versions.
  #
  # @api private
  module CommandRecorder
    def create_function(*args, **kwargs, &block)
      record(:create_function, args, kwargs, &block)
    end

    def drop_function(*args, **kwargs, &block)
      record(:drop_function, args, kwargs, &block)
    end

    def update_function(*args, **kwargs, &block)
      record(:update_function, args, kwargs, &block)
    end

    def invert_create_function(args, kwargs)
      Fx::CommandRecorder::Inversion.invert(:create_function, args, kwargs)
    end

    def invert_drop_function(args, kwargs)
      Fx::CommandRecorder::Inversion.invert(:drop_function, args, kwargs)
    end

    def invert_update_function(args, kwargs)
      Fx::CommandRecorder::Inversion.invert(:update_function, args, kwargs)
    end

    def create_trigger(*args, **kwargs, &block)
      record(:create_trigger, args, kwargs, &block)
    end

    def drop_trigger(*args, **kwargs, &block)
      record(:drop_trigger, args, kwargs, &block)
    end

    def update_trigger(*args, **kwargs, &block)
      record(:update_trigger, args, kwargs, &block)
    end

    def invert_create_trigger(args, kwargs)
      Fx::CommandRecorder::Inversion.invert(:create_trigger, args, kwargs)
    end

    def invert_drop_trigger(args, kwargs)
      Fx::CommandRecorder::Inversion.invert(:drop_trigger, args, kwargs)
    end

    def invert_update_trigger(args, kwargs)
      Fx::CommandRecorder::Inversion.invert(:update_trigger, args, kwargs)
    end
  end
end
