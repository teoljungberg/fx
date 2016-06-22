module MigrationsHelper
  def run_migration(migration, directions)
    silence_stream(STDOUT) do
      Array.wrap(directions).each do |direction|
        migration.migrate(direction)
      end
    end
  end

  def connection
    @_connection ||= ActiveRecord::Base.connection
  end
end

RSpec.configure do |config|
  config.include MigrationsHelper
end
