require "fx/adapters/query_executor"

module Fx
  module Adapters
    class Postgres
      # Executes database queries and maps results to domain objects.
      # @api private
      # @deprecated Use {Fx::Adapters::QueryExecutor} directly. This constant
      #   is kept for backward compatibility.
      QueryExecutor = Fx::Adapters::QueryExecutor
    end
  end
end
