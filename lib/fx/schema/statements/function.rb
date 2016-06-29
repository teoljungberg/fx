require "rails"

module Fx
  module Schema
    module Statements
      module Function
        def create_function(name, version: 1, sql_definition: nil)
          if version.nil? && sql_definition.nil?
            raise(
              ArgumentError,
              "version or sql_definition must be specified",
            )
          end
          sql_definition = sql_definition ||
            definition(name: name, version: version)

          Fx.database.create_function(sql_definition)
        end

        def drop_function(name, revert_to_version: nil)
          Fx.database.drop_function(name)
        end

        def update_function(name, version: nil, revert_to_version: nil)
          if version.nil?
            raise ArgumentError, "version is required"
          end

          drop_function(name)
          create_function(name, version: version)
        end

        private

        def definition(*args)
          Fx::Definition.new(*args).to_sql
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send(
  :include,
  Fx::Schema::Statements::Function,
)
