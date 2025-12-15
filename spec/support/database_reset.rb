module DatabaseReset
  def self.call
    connection = ActiveRecord::Base.connection
    connection.execute("SET search_path TO DEFAULT;")

    connection.execute <<~SQL
      DO $$
      DECLARE
        schema_name TEXT;
      BEGIN
        FOR schema_name IN
          SELECT nspname FROM pg_namespace
          WHERE nspname NOT LIKE 'pg_%'
            AND nspname != 'information_schema'
        LOOP
          EXECUTE format('DROP SCHEMA IF EXISTS %I CASCADE', schema_name);
        END LOOP;
      END $$;
    SQL

    connection.execute("CREATE SCHEMA public;")
    connection.schema_search_path = "public"
  end
end
