module DatabaseReset
  def self.call
    connection = ActiveRecord::Base.connection
    connection.execute("SET search_path TO DEFAULT;")
    connection.execute("DROP SCHEMA IF EXISTS public CASCADE;")
    connection.execute("CREATE SCHEMA public;")
    connection.schema_search_path = "public"
  end
end
