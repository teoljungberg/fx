require "fx/trigger"

module Fx
  module Adapters
    class Postgres
      # Fetches defined triggers from the postgres connection.
      # @api private
      class Triggers
        # The SQL query used by F(x) to retrieve the triggers considered
        # dumpable into `db/schema.rb`.
        TRIGGERS_WITH_DEFINITIONS_QUERY = <<~SQL
          SELECT
              pt.tgname AS name,
              pg_get_triggerdef(pt.oid) AS definition
          FROM pg_trigger pt
        SQL

        # Wraps #all as a static facade.
        #
        # @return [Array<Fx::Trigger>]
        def self.all(*args)
          new(*args).all
        end

        def initialize(connectable = ActiveRecord::Base.connection)
          @connectable = connectable
        end

        # All of the triggers that this connection has defined.
        #
        # @return [Array<Fx::Trigger>]
        def all
          triggers_from_postgres.map { |trigger| to_fx_trigger(trigger) }
        end

        private

        attr_reader :connectable

        def triggers_from_postgres
          connectable.execute(TRIGGERS_WITH_DEFINITIONS_QUERY)
        end

        def to_fx_trigger(result)
          Fx::Trigger.new(result)
        end
      end
    end
  end
end
