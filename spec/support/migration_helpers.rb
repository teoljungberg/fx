module MigrationsHelper
  def run_migration(migration, directions)
    silence_stream($stdout) do
      Array.wrap(directions).each do |direction|
        migration.migrate(direction)
      end
    end
  end

  def migration_class
    if Rails::VERSION::MAJOR >= 5
      ::ActiveRecord::Migration[5.0]
    else
      ::ActiveRecord::Migration
    end
  end

  def connection
    @_connection ||= ActiveRecord::Base.connection
  end
end

RSpec.configure do |config|
  config.include MigrationsHelper
end
