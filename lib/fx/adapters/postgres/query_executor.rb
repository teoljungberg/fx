module Fx
  module Adapters
    class Postgres
      # Executes database queries and maps results to domain objects.
      # @api private
      class QueryExecutor
        def self.call(...)
          new(...).call
        end

        def initialize(connection:, query:, model_class:)
          @connection = connection
          @query = query
          @model_class = model_class
        end

        # Executes the query and maps results to domain objects.
        #
        # @return [Array] Array of domain objects (Functions or Triggers)
        def call
          results_from_postgres.map { |result| model_class.new(result) }
        end

        private

        attr_reader :connection, :query, :model_class

        def results_from_postgres
          connection.execute(query)
        end
      end
    end
  end
end
