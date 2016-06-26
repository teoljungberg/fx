module Fx
  module CommandRecorder
    module Trigger
      def create_trigger(*args)
        record(:create_trigger, args)
      end

      def drop_trigger(*args)
        record(:drop_trigger, args)
      end

      def update_trigger(*args)
        record(:update_trigger, args)
      end

      def invert_create_trigger(args)
        [:drop_trigger, args]
      end

      def invert_drop_trigger(args)
        perform_inversion(:create_trigger, args)
      end

      def invert_update_trigger(args)
        perform_inversion(:update_trigger, args)
      end
    end
  end
end
