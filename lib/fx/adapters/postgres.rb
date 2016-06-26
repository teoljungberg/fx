module Fx
  module Adapters
    module Postgres
      FUNCTIONS_WITH_DEFINITIONS_QUERY = <<~SQL
        SELECT
            pp.proname,
            pp.prosrc
        FROM pg_proc pp
        INNER JOIN pg_namespace pn
            ON (pp.pronamespace = pn.oid)
        INNER JOIN pg_language pl
            ON (pp.prolang = pl.oid)
        WHERE pl.lanname NOT IN ('c','internal')
            AND pn.nspname NOT LIKE 'pg_%'
            AND pn.nspname <> 'information_schema'
      SQL

      def self.functions
        execute(FUNCTIONS_WITH_DEFINITIONS_QUERY).
          map { |result| Fx::Function.new(result) }
      end

      def self.create_function(sql_definition)
        execute sql_definition
      end

      def self.drop_function(name)
        execute "DROP FUNCTION #{name}();"
      end

      private

      def self.execute(sql, base = ActiveRecord::Base)
        base.connection.execute(sql)
      end
      private_class_method :execute
    end
  end
end
