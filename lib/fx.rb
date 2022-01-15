require "fx/version"
require "fx/adapters/postgres"
require "fx/command_recorder"
require "fx/configuration"
require "fx/definition"
require "fx/function"
require "fx/migration"
require "fx/statements"
require "fx/schema_dumper"
require "fx/trigger"
require "fx/railtie"

# F(x) adds methods `ActiveRecord::Migration` to create and manage database
# triggers and functions in Rails applications.
module Fx
  # Hooks Fx into Rails.
  #
  # Enables fx migration methods, migration reversability, and `schema.rb`
  # dumping.
  def self.load
    ActiveRecord::Migration::CommandRecorder.send(
      :include,
      Fx::CommandRecorder,
    )

    ActiveRecord::SchemaDumper.send(
      :prepend,
      Fx::SchemaDumper,
    )

    ActiveRecord::ConnectionAdapters::AbstractAdapter.send(
      :include,
      Fx::Statements,
    )

    ActiveRecord::Migration.send(
      :include,
      Fx::Migration,
    )
  end

  # The current database adapter used by F(x).
  #
  # This defaults to {Fx::Adapters::Postgres} but can be overridden
  # via {Configuration}.
  def self.database
    configuration.database
  end
end
