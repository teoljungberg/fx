module Fx
  module Adapters
    class Postgres
      # Decorates an ActiveRecord connection with methods that help determine
      # the connections capabilities.
      #
      # Every attempt is made to use the versions of these methods defined by
      # Rails where they are available and public before falling back to our own
      # implementations for older Rails versions.
      #
      # @api private
      class Connection < SimpleDelegator
      end
    end
  end
end
