module Fx
  module CommandRecorder
    # @api private
    module Function
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
    end
  end
end
