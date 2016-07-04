require "fx/version"
require "fx/adapters/postgres"
require "fx/command_recorder"
require "fx/configuration"
require "fx/definition"
require "fx/function"
require "fx/schema/statements"
require "fx/schema_dumper"
require "fx/trigger"

# F(x) adds methods `ActiveRecord::Migration` to create and manage database
# triggers and functions in Rails applications.
module Fx
  # The current database adapter used by F(x).
  #
  # This defaults to {Fx::Adapters::Postgres} but can be overridden
  # via {Configuration}.
  def self.database
    configuration.database
  end
end
