module Fx
  module Adapters
    module Postgres
      def self.functions_with_definitions_query
        <<~EOS
          SELECT
              pp.proname,
              pp.prosrc
          FROM pg_proc pp
          INNER JOIN pg_namespace pn ON (pp.pronamespace = pn.oid)
          INNER JOIN pg_language pl ON (pp.prolang = pl.oid)
          WHERE pl.lanname NOT IN ('c','internal')
            AND pn.nspname NOT LIKE 'pg_%'
            AND pn.nspname <> 'information_schema'
        EOS
      end

      def self.create_function(name:, version: 1)
        function(name: name, version: version)
      end

      def self.drop_function(name)
        "DROP FUNCTION #{name}();"
      end

      private

      def self.function(name:, version:)
        File.read ::Rails.root.join(
          "db",
          "functions",
          "#{name}_v#{version}.sql",
        )
      end
      private_class_method :function
    end
  end
end
