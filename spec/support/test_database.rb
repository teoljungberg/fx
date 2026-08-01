require "securerandom"

module Fx
  # Builds fast, isolated PostgreSQL databases for tests from a reusable
  # template database.
  #
  # This follows the "template database" pattern popularized by pgtestdb
  # (https://brandur.org/fragments/pgtestdb). A template database is created
  # once and its full schema — tables, F(x) functions, and triggers — is loaded
  # into it. Each test then clones a fresh database from that template with
  # `CREATE DATABASE ... TEMPLATE ...`, which PostgreSQL performs as a fast
  # file-level copy.
  #
  # Because every test receives its own real database — rather than sharing a
  # single, transaction-wrapped one — functions and triggers that depend on
  # committed data behave exactly as they do in production, and Rails fixtures
  # load into each clone independently.
  #
  # While a template is being built and while a cloned instance is in use, the
  # `connection_class` (`ActiveRecord::Base` by default) is repointed at that
  # database so schema loads, models, and fixtures operate against it, and its
  # original connection is restored afterwards. `CREATE DATABASE` and
  # `DROP DATABASE` — which cannot run while connected to their target — are
  # issued by briefly repointing the same class at a maintenance database
  # (`"postgres"` by default).
  #
  # @example Build a template once and clone a database per test
  #   test_database = Fx::TestDatabase.new(
  #     ActiveRecord::Base.connection_db_config.configuration_hash,
  #     template: "fx_test_template"
  #   )
  #
  #   # Build the template exactly once (e.g. in a `before(:suite)` hook):
  #   test_database.create_template do |connection|
  #     load(Rails.root.join("db/schema.rb")) # loads tables + F(x) objects
  #   end
  #
  #   # In each test, clone a throwaway database, run against it, and drop it:
  #   test_database.with_instance do |connection|
  #     User.create!(name: "alice")          # a BEFORE INSERT trigger fires
  #     User.find_by(name: "alice").upper_name # => "ALICE"
  #   end
  class TestDatabase
    DEFAULT_MAINTENANCE_DATABASE = "postgres".freeze

    IDENTIFIER = /\A[a-zA-Z_][a-zA-Z0-9_]*\z/

    # Raised when a database name is not a safe PostgreSQL identifier.
    class InvalidName < ArgumentError; end

    # @param config [Hash] Base connection configuration (as returned by
    #   `ActiveRecord::Base.connection_db_config.configuration_hash`). Its
    #   `:database` entry is ignored — the template and instance names are used
    #   instead.
    # @param template [String] Name of the template database to build and clone
    #   from.
    # @param connection_class [Class] The `ActiveRecord::Base` (sub)class whose
    #   connection is repointed at the template while it is built and at each
    #   instance while it is in use. Defaults to `ActiveRecord::Base`.
    # @param maintenance_database [String] A database to connect to while
    #   issuing `CREATE DATABASE` / `DROP DATABASE`, which cannot run while
    #   connected to their target. Defaults to `"postgres"`.
    # @param mark_as_template [Boolean] Whether to flag the template with
    #   `datistemplate`, which lets roles other than the owner clone it.
    #   Defaults to `true`.
    def initialize(config, template:, connection_class: ActiveRecord::Base, maintenance_database: DEFAULT_MAINTENANCE_DATABASE, mark_as_template: true)
      @config = config.symbolize_keys
      @template = validate_name!(template.to_s)
      @connection_class = connection_class
      @maintenance_database = maintenance_database.to_s
      @mark_as_template = mark_as_template
      @available = []
      @checked_out = []
    end

    # Creates the template database and loads a schema into it.
    #
    # Any existing template with the same name is dropped first, so the template
    # always reflects the current schema. The `connection_class` is connected to
    # the freshly created template for the duration of the block and restored
    # afterwards.
    #
    # @yieldparam connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
    #   A connection to the template database.
    # @return [self]
    def create_template
      drain_pool
      drop_orphaned_instances
      drop_template
      admin { |connection| connection.execute("CREATE DATABASE #{quote(@template)}") }

      using(@template) do |connection|
        yield connection if block_given?
      end

      mark_template if @mark_as_template
      self
    end

    # @return [Boolean] Whether the template database exists.
    def template_exists?
      database_exists?(@template)
    end

    # Clones a fresh database from the template.
    #
    # @param name [String] Name for the new database. Defaults to a unique name
    #   derived from the template.
    # @return [String] The name of the created database.
    def create_instance(name = generate_name)
      validate_name!(name)
      admin do |connection|
        terminate_connections(connection, @template)
        connection.execute(
          "CREATE DATABASE #{quote(name)} TEMPLATE #{quote(@template)}"
        )
      end
      name
    end

    # @param name [String] Database name.
    # @return [Hash] Connection configuration pointing at the named database.
    def instance_config(name)
      config_for(name)
    end

    # Drops a database previously created with {#create_instance}.
    #
    # @param name [String] Database name.
    # @return [void]
    def drop_instance(name)
      drop_database(name)
    end

    # Drops the template database.
    #
    # @return [void]
    def drop_template
      return unless template_exists?

      unmark_template if @mark_as_template
      drop_database(@template)
    end

    # Clones a fresh database from the template, connects the
    # `connection_class` to it, yields, and disposes of it afterwards. The
    # original connection is restored when the block returns.
    #
    # With `reuse: false` (the default), the database is dropped after the
    # block. With `reuse: true`, it is instead taken from — and, once the block
    # succeeds, cleaned and returned to — a pool of databases kept alive for the
    # current template, which is markedly faster than cloning afresh every time
    # (see {#checkout}). If the block raises while reusing, the database is left
    # in place, out of the pool, so its state can be inspected; {#shutdown}
    # drops it later.
    #
    # @param name [String] Name for the new database. Defaults to a unique name.
    #   Ignored when `reuse: true`.
    # @param reuse [Boolean] Whether to check the database out of the reuse
    #   pool instead of cloning and dropping one.
    # @yieldparam connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
    #   A connection to the database.
    # @return The value returned by the block.
    def with_instance(name = generate_name, reuse: false)
      return with_pooled_instance { |connection| yield connection } if reuse

      create_instance(name)
      using(name) do |connection|
        yield connection
      end
    ensure
      drop_instance(name) unless reuse
    end

    # Checks a clean database out of the reuse pool, cloning a new one only when
    # none is available.
    #
    # Reuse is the optimization that makes template databases competitive with
    # transaction-based test isolation for large suites: cloning costs on the
    # order of 100ms, while cleaning and reusing a database costs a fraction of
    # that. The caller is responsible for returning the database with {#checkin}
    # (to clean and pool it) or {#discard} (to drop it). {#with_instance} with
    # `reuse: true` does this automatically.
    #
    # Databases in the pool are tied to the current template; {#create_template}
    # and {#shutdown} drop them all.
    #
    # @return [String] The name of a database ready to use.
    def checkout
      name = @available.pop || create_instance
      @checked_out << name
      name
    end

    # Cleans a checked-out database — dropping every non-system schema and
    # recreating `public`, so no data or schema objects leak between uses —
    # and returns it to the reuse pool.
    #
    # @param name [String] A database returned by {#checkout}.
    # @return [void]
    def checkin(name)
      @checked_out.delete(name)
      clean(name)
      @available << name
      nil
    end

    # Drops a checked-out or pooled database instead of reusing it.
    #
    # @param name [String] A database name.
    # @return [void]
    def discard(name)
      @checked_out.delete(name)
      @available.delete(name)
      drop_instance(name)
    end

    # Drops every database in the reuse pool (available or checked out), any
    # orphaned instances from earlier runs, and the template. Call this once
    # the suite finishes.
    #
    # @return [void]
    def shutdown
      drain_pool
      drop_orphaned_instances
      drop_template
    end

    private

    attr_reader :config, :template, :connection_class, :maintenance_database

    def config_for(database)
      config.merge(database: database)
    end

    def with_pooled_instance
      name = checkout
      result = using(name) { |connection| yield connection }
      checkin(name)
      result
    end

    # Resets a pooled database to a clean state by dropping every non-system
    # schema and recreating `public`, mirroring `DatabaseReset`.
    def clean(name)
      using(name) do |connection|
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

    def drain_pool
      (@available + @checked_out).uniq.each { |name| drop_instance(name) }
      @available.clear
      @checked_out.clear
    end

    # Drops any clone databases that match this template's instance naming
    # pattern but are not tracked by the current pool. This cleans up after
    # interrupted runs where +shutdown+ was not reached.
    def drop_orphaned_instances
      admin do |connection|
        pattern = "#{template}_%"
        names = connection.select_values(<<~SQL)
          SELECT datname FROM pg_database
          WHERE datname LIKE #{connection.quote(pattern)}
          ORDER BY datname
        SQL
        names.each do |name|
          validate_name!(name)
          terminate_connections(connection, name)
          connection.execute("DROP DATABASE IF EXISTS #{quote(name)} WITH (FORCE)")
        end
      end
    end

    # Connects +connection_class+ to +database+ for the duration of the block,
    # restoring whatever it was configured with afterwards.
    def using(database)
      previous = current_db_config
      connection_class.establish_connection(config_for(database))
      yield connection_class.connection
    ensure
      connection_class.remove_connection
      connection_class.establish_connection(previous) if previous
    end

    # The database config +connection_class+ is currently configured with, or
    # +nil+ if it has none. A configured class may not hold a live connection
    # yet (connections are established lazily), so this cannot rely on
    # +connected?+.
    def current_db_config
      connection_class.connection_db_config
    rescue ActiveRecord::ConnectionNotEstablished
      nil
    end

    # Connects +connection_class+ to the maintenance database and yields the
    # connection for administrative statements — `CREATE DATABASE`,
    # `DROP DATABASE`, and catalog updates — which cannot run while connected to
    # their target database.
    def admin(&block)
      using(maintenance_database, &block)
    end

    def generate_name
      "#{template}_#{SecureRandom.hex(8)}"
    end

    def mark_template
      set_datistemplate(true)
    end

    def unmark_template
      set_datistemplate(false)
    end

    def set_datistemplate(value)
      admin do |connection|
        connection.execute(
          "UPDATE pg_database SET datistemplate = #{value} " \
          "WHERE datname = #{connection.quote(template)}"
        )
      end
    end

    def terminate_connections(connection, database)
      connection.execute(<<~SQL)
        SELECT pg_terminate_backend(pid)
        FROM pg_stat_activity
        WHERE datname = #{connection.quote(database)}
          AND pid <> pg_backend_pid()
      SQL
    end

    def drop_database(name)
      validate_name!(name)
      admin do |connection|
        terminate_connections(connection, name)
        connection.execute("DROP DATABASE IF EXISTS #{quote(name)} WITH (FORCE)")
      end
    end

    def database_exists?(name)
      admin do |connection|
        connection.select_value(
          "SELECT 1 FROM pg_database WHERE datname = #{connection.quote(name)}"
        ).present?
      end
    end

    # Quotes a validated database name as a PostgreSQL identifier.
    def quote(name)
      %("#{validate_name!(name)}")
    end

    def validate_name!(name)
      unless IDENTIFIER.match?(name)
        raise InvalidName, "#{name.inspect} is not a valid PostgreSQL identifier"
      end
      name
    end
  end
end
