module Fx
  module CommandRecorder
    # @api private
    module Aggregate
      def create_aggregate(*args)
        record(:create_aggregate, args)
      end

      def drop_aggregate(*args)
        record(:drop_aggregate, args)
      end

      def update_aggregate(*args)
        record(:update_aggregate, args)
      end

      def invert_create_aggregate(args)
        [:drop_aggregate, args]
      end

      def invert_drop_aggregate(args)
        perform_inversion(:create_aggregate, args)
      end

      def invert_update_aggregate(args)
        perform_inversion(:update_aggregate, args)
      end
    end
  end
end
