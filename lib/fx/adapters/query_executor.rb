module Fx
  module Adapters
    # Executes database queries and maps results to domain objects.
    #
    # This is a reusable helper for adapter implementations. It runs a query
    # against the given connection and maps each returned row into an instance
    # of the provided model class.
    class QueryExecutor
      # Executes the query and maps results to domain objects.
      #
      # @param connection [#execute] A connection object that responds to
      #   `#execute`.
      # @param query [String] The SQL query to execute.
      # @param model_class [Class] The class used to wrap each returned row.
      # @return [Array] Array of domain objects.
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
        results_from_database.map { |result| model_class.new(result) }
      end

      private

      attr_reader :connection, :query, :model_class

      def results_from_database
        connection.execute(query)
      end
    end
  end
end
