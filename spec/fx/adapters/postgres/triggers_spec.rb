require "spec_helper"
require "shellwords"

RSpec.describe Fx::Adapters::Postgres::Triggers, :db do
  describe ".all" do
    it "returns `Trigger` objects" do
      connection = ActiveRecord::Base.connection
      connection.execute <<~SQL
        CREATE TABLE users (
            id int PRIMARY KEY,
            name varchar(256),
            upper_name varchar(256)
        );
      SQL
      connection.execute <<~SQL
        CREATE OR REPLACE FUNCTION uppercase_users_name()
        RETURNS trigger AS $$
        BEGIN
          NEW.upper_name = UPPER(NEW.name);
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      SQL
      connection.execute <<~SQL
        CREATE TRIGGER uppercase_users_name
            BEFORE INSERT ON users
            FOR EACH ROW
            EXECUTE FUNCTION uppercase_users_name();
      SQL

      triggers = Fx::Adapters::Postgres::Triggers.all(connection)

      first = triggers.first
      expect(triggers.size).to eq(1)
      expect(first.name).to eq("uppercase_users_name")
      expect(first.definition).to include("BEFORE INSERT")
      expect(first.definition).to match(/ON [public.ser|]/)
      expect(first.definition).to include("FOR EACH ROW")
      expect(first.definition).to include("EXECUTE FUNCTION uppercase_users_name()")

      connection.execute "CREATE SCHEMA IF NOT EXISTS other;"
      connection.execute "SET search_path = 'other';"

      triggers = Fx::Adapters::Postgres::Triggers.all(connection)

      expect(triggers).to be_empty
    end

    it "ignores triggers created by an extension script" do
      skip_unless_superuser
      connection = ActiveRecord::Base.connection

      with_real_extension(connection) do |schema|
        # Pin what Postgres actually records for a script-created trigger:
        # no membership row on the trigger itself; the table the trigger
        # sits on is the extension member the dump query tests.
        membership = connection.select_value(<<~SQL)
          SELECT 1
          FROM pg_depend
          WHERE classid = 'pg_trigger'::regclass
              AND objid = (SELECT oid FROM pg_trigger WHERE tgname = 'events_bounce')
              AND deptype = 'e';
        SQL
        expect(membership).to be_nil

        connection.execute "SET search_path = 'public', '#{schema}';"

        triggers = Fx::Adapters::Postgres::Triggers.all(connection)

        expect(triggers).to be_empty
      end
    end

    it "ignores all triggers on tables that belong to an extension, matching pg_dump" do
      skip_unless_superuser
      connection = ActiveRecord::Base.connection

      create_places_touch_trigger(connection)

      # A user trigger on an extension-owned table is not dumped, even when
      # the trigger and its function are not extension members: the table
      # only exists because the extension script created it, so recreating
      # the trigger is migration work, not schema dump work. pg_dump makes
      # the same choice.
      with_extension_members("TABLE public.places") do
        triggers = Fx::Adapters::Postgres::Triggers.all(connection)

        expect(triggers).to be_empty
      end
    end

    it "returns triggers on user tables that call extension-owned functions" do
      skip_unless_superuser
      connection = ActiveRecord::Base.connection

      create_set_updated_at_trigger(connection)

      with_extension_members("FUNCTION public.moddatetime()") do
        triggers = Fx::Adapters::Postgres::Triggers.all(connection)

        expect(triggers.map(&:name)).to eq(["set_updated_at"])
      end
    end

    def with_extension_members(*objects)
      connection = ActiveRecord::Base.connection
      added = []

      objects.each do |object|
        connection.execute "ALTER EXTENSION plpgsql ADD #{object};"
        added << object
      end

      yield
    ensure
      added.each do |object|
        connection.execute "ALTER EXTENSION plpgsql DROP #{object};"
      end
    end

    # Installs a real extension (control file + SQL script that creates a
    # function, table, and trigger inside the script) into the server
    # container, so the spec pins what Postgres records for script-created
    # triggers. Needs podman or docker access to the server's container;
    # skips when neither is available, like the superuser skip above.
    def with_real_extension(connection)
      engine = container_engine
      container = ENV["FX_PG_CONTAINER"]
      container = "fx-postgres" if container.nil? || container.empty?
      unless engine && system(engine, "exec", container, "true",
        out: File::NULL, err: File::NULL)
        if ENV["CI"]
          raise "CI must provide the #{container} container via podman or docker"
        else
          skip "requires the #{container} container reachable via podman or docker"
        end
      end

      sharedir = `#{engine} exec #{container} pg_config --sharedir`.strip
      raise "#{container} did not report a sharedir" if sharedir.empty?
      extension_dir = "#{sharedir}/extension"
      install_container_file(engine, container, "#{extension_dir}/fx_ext_fixture.control", <<~CONTROL)
        default_version = '1.0'
        relocatable = false
        schema = fx_ext_fixture_schema
      CONTROL
      install_container_file(engine, container, "#{extension_dir}/fx_ext_fixture--1.0.sql", <<~SQL)
        CREATE FUNCTION fx_ext_fixture_schema.bounce() RETURNS trigger AS $$
        BEGIN
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
        CREATE TABLE fx_ext_fixture_schema.events (id int primary key);
        CREATE TRIGGER events_bounce
            BEFORE INSERT ON fx_ext_fixture_schema.events
            FOR EACH ROW
            EXECUTE FUNCTION fx_ext_fixture_schema.bounce();
      SQL

      connection.execute "DROP EXTENSION IF EXISTS fx_ext_fixture CASCADE;"
      connection.execute "CREATE EXTENSION fx_ext_fixture;"

      yield "fx_ext_fixture_schema"
    ensure
      connection&.execute "DROP EXTENSION IF EXISTS fx_ext_fixture CASCADE;"
      if engine && extension_dir
        ["fx_ext_fixture.control", "fx_ext_fixture--1.0.sql"].each do |file|
          system(engine, "exec", container, "rm", "-f", "#{extension_dir}/#{file}",
            out: File::NULL, err: File::NULL)
        end
      end
    end

    # Writes the file and makes it readable in one exec. Content travels
    # base64-encoded on the command line: `podman exec -i` stdin is
    # unreliable under bundler (arrives empty), and `podman cp` preserves
    # the source mode (0600), which the postgres server cannot read.
    def install_container_file(engine, container, path, content)
      encoded = [content].pack("m0")
      system(engine, "exec", container, "sh", "-c",
        "printf %s #{Shellwords.escape(encoded)} | base64 -d > #{path} " \
        "&& chmod 644 #{path}",
        out: File::NULL, err: File::NULL) or
        raise "could not install #{path} into #{container}"
    end

    def container_engine
      %w[podman docker].each do |engine|
        return engine if system(engine, "info", out: File::NULL, err: File::NULL)
      end
      nil
    end

    def skip_unless_superuser
      superuser = ActiveRecord::Base.connection.select_value(
        "SELECT rolsuper FROM pg_roles WHERE rolname = current_user;"
      )
      unless superuser
        if ENV["CI"]
          raise "CI must run these specs against a superuser connection"
        else
          skip "requires a superuser connection"
        end
      end
    end

    def create_places_touch_trigger(connection)
      connection.execute <<~SQL
        CREATE TABLE places (id int);
        CREATE FUNCTION touch_places() RETURNS trigger AS $$
        BEGIN
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
        CREATE TRIGGER places_touch
            BEFORE UPDATE ON places
            FOR EACH ROW
            EXECUTE FUNCTION touch_places();
      SQL
    end

    def create_set_updated_at_trigger(connection)
      connection.execute <<~SQL
        CREATE TABLE posts (updated_at timestamp);
        CREATE FUNCTION moddatetime() RETURNS trigger AS $$
        BEGIN
          NEW.updated_at = now();
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
        CREATE TRIGGER set_updated_at
            BEFORE UPDATE ON posts
            FOR EACH ROW
            EXECUTE FUNCTION moddatetime();
      SQL
    end
  end
end
