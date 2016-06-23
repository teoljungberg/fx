require "rails"

module Fx
  module Schema
    module Statements
      def create_function(name, version: 1)
        execute Fx.database.create_function(name: name, version: version)
      end

      def drop_function(name, revert_to_version: nil)
        execute Fx.database.drop_function(name)
      end

      def update_function(name, version: nil, revert_to_version: nil)
        if version.nil?
          raise ArgumentError, "version is required"
        end

        drop_function(name)
        create_function(name, version: version)
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send(
  :include,
  Fx::Schema::Statements,
)
