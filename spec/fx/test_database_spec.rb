require "spec_helper"

# `Fx::TestDatabase` is defined in spec/support and loaded by spec_helper.
#
# A named connection class so the helper never disturbs the shared
# `ActiveRecord::Base` connection the rest of the suite relies on.
# `establish_connection` rejects anonymous classes.
class FxTestDatabaseConnection < ActiveRecord::Base
  self.abstract_class = true
end

# A second named connection class used to read from cloned instances directly.
class FxTestDatabaseInstance < ActiveRecord::Base
  self.abstract_class = true
end

RSpec.describe Fx::TestDatabase do
  let(:config) { ActiveRecord::Base.connection_db_config.configuration_hash }
  let(:connection_class) { FxTestDatabaseConnection }
  let(:test_database) do
    described_class.new(
      config,
      template: "fx_test_database_template",
      connection_class: connection_class
    )
  end

  before do
    test_database.create_template { |connection| load_schema(connection) }
  end

  after do
    test_database.shutdown
  end

  it "loads tables, functions, and triggers into the template" do
    test_database.with_instance do |connection|
      adapter = Fx::Adapters::Postgres.new(connection_class)

      expect(connection.data_source_exists?(:users)).to be(true)
      expect(adapter.functions.map(&:name)).to include("set_upper_name")
      expect(adapter.triggers.map(&:name)).to include("set_upper_name")
    end
  end

  it "clones an instance whose triggers fire on real inserts" do
    upper_name =
      test_database.with_instance do |connection|
        connection.execute("INSERT INTO users (name) VALUES ('alice')")
        connection.select_value("SELECT upper_name FROM users")
      end

    expect(upper_name).to eq("ALICE")
  end

  it "isolates instances cloned from the same template" do
    first = test_database.create_instance
    second = test_database.create_instance

    begin
      first_count = count_users(test_database.instance_config(first)) do |connection|
        connection.execute("INSERT INTO users (name) VALUES ('alice')")
      end
      second_count = count_users(test_database.instance_config(second))

      expect(first_count).to eq(1)
      expect(second_count).to eq(0)
    ensure
      test_database.drop_instance(first)
      test_database.drop_instance(second)
    end
  end

  it "loads Rails fixtures into a cloned instance" do
    names =
      test_database.with_instance do |connection|
        connection.insert_fixtures_set(
          "users" => [{"id" => 1, "name" => "bob"}]
        )
        connection.select_values("SELECT name FROM users ORDER BY id")
      end

    expect(names).to eq(["bob"])
  end

  it "restores the connection_class connection after use" do
    connection_class.establish_connection(config)

    test_database.with_instance { |connection| connection.select_value("SELECT 1") }

    expect(connection_class.connection_db_config.database).to eq(config[:database])
  end

  it "reports whether the template exists" do
    expect(test_database.template_exists?).to be(true)

    test_database.drop_template

    expect(test_database.template_exists?).to be(false)
  end

  it "rebuilds the template on create_template" do
    test_database.create_instance("fx_test_database_probe")
    test_database.drop_instance("fx_test_database_probe")

    expect { test_database.create_template { |c| load_schema(c) } }
      .not_to raise_error
  end

  it "rejects database names that are not valid identifiers" do
    expect { test_database.create_instance("users; DROP DATABASE postgres") }
      .to raise_error(Fx::TestDatabase::InvalidName)

    expect {
      described_class.new(config, template: "1-bad-name")
    }.to raise_error(Fx::TestDatabase::InvalidName)
  end

  it "cleans up orphaned instances from an interrupted run" do
    leaked = test_database.checkout
    test_database.instance_variable_get(:@available).clear
    test_database.instance_variable_get(:@checked_out).clear

    fresh_database = described_class.new(
      config,
      template: "fx_test_database_template",
      connection_class: connection_class
    )
    fresh_database.create_template { |connection| load_schema(connection) }

    expect(database_exists?(leaked)).to be(false)

    fresh_database.shutdown
  end

  describe "reuse pool" do
    it "reuses a pooled database across checkouts" do
      first = test_database.checkout
      test_database.checkin(first)

      expect(test_database.checkout).to eq(first)
    end

    it "clones a new database when the pool is empty" do
      first = test_database.checkout
      second = test_database.checkout

      expect(second).not_to eq(first)
    end

    it "cleans data between reuses" do
      test_database.with_instance(reuse: true) do |connection|
        connection.execute("INSERT INTO users (name) VALUES ('alice')")
      end

      test_database.with_instance(reuse: true) do |connection|
        expect(connection.data_source_exists?(:users)).to be(false)
      end
    end

    it "keeps a failed reuse database out of the pool for inspection" do
      leaked =
        begin
          test_database.with_instance(reuse: true) do |connection|
            connection.select_value("SELECT current_database()").tap { raise "boom" }
          end
        rescue RuntimeError
          test_database.instance_variable_get(:@checked_out).last
        end

      reused = test_database.with_instance(reuse: true) do |connection|
        connection.select_value("SELECT current_database()")
      end

      expect(reused).not_to eq(leaked)
      expect(database_exists?(leaked)).to be(true)
    end

    it "drops pooled databases when the template is rebuilt" do
      name = test_database.checkout
      test_database.checkin(name)
      expect(database_exists?(name)).to be(true)

      test_database.create_template { |connection| load_schema(connection) }

      expect(database_exists?(name)).to be(false)
    end

    it "drops pooled databases and the template on shutdown" do
      name = test_database.checkout
      test_database.checkin(name)

      test_database.shutdown

      expect(database_exists?(name)).to be(false)
      expect(test_database.template_exists?).to be(false)
    end
  end

  # Connects to the given database, optionally yields the connection, and
  # returns the number of rows in `users`.
  def count_users(instance_config)
    FxTestDatabaseInstance.establish_connection(instance_config)
    yield FxTestDatabaseInstance.connection if block_given?
    FxTestDatabaseInstance.connection.select_value("SELECT count(*) FROM users")
  ensure
    FxTestDatabaseInstance.remove_connection
  end

  def database_exists?(name)
    FxTestDatabaseInstance.establish_connection(config.merge(database: "postgres"))
    connection = FxTestDatabaseInstance.connection
    connection
      .select_value("SELECT 1 FROM pg_database WHERE datname = #{connection.quote(name)}")
      .present?
  ensure
    FxTestDatabaseInstance.remove_connection
  end

  def load_schema(connection)
    connection.create_table(:users, force: true) do |t|
      t.string(:name)
      t.string(:upper_name)
    end
    connection.execute(<<~SQL)
      CREATE OR REPLACE FUNCTION set_upper_name()
      RETURNS trigger AS $$
      BEGIN
        NEW.upper_name := upper(NEW.name);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    connection.execute(<<~SQL)
      CREATE TRIGGER set_upper_name
        BEFORE INSERT ON users
        FOR EACH ROW
        EXECUTE FUNCTION set_upper_name();
    SQL
  end
end
