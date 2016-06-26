module Fx
  module Schema
    module Statements
      module Trigger
        DEFINTION_TYPE = "trigger".freeze

        def create_trigger(name, version: 1, on: nil, sql_definition: nil)
          if version.nil? && sql_definition.nil?
            raise(
              ArgumentError,
              "version or sql_definition must be specified",
            )
          end
          sql_definition = sql_definition ||
            Fx::Definition.new(
              name: name,
              version: version,
              type: DEFINTION_TYPE,
            ).to_sql

          Fx.database.create_trigger(sql_definition)
        end

        def drop_trigger(name, on:, revert_to_version: nil)
          Fx.database.drop_trigger(name, on: on)
        end

        def update_trigger(name, version: nil, on: nil, revert_to_version: nil)
          if version.nil?
            raise ArgumentError, "version is required"
          elsif on.nil?
            raise ArgumentError, "on is required"
          end

          drop_trigger(name, on: on)
          create_trigger(name, version: version)
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send(
  :include,
  Fx::Schema::Statements::Trigger,
)
