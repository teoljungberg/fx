require "rails"

require "fx/version"
require "fx/adapters/postgres"
require "fx/command_recorder"
require "fx/configuration"
require "fx/definition"
require "fx/function"
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
    ActiveRecord::Migration::CommandRecorder.include(Fx::CommandRecorder)
    ActiveRecord::ConnectionAdapters::AbstractAdapter.include(Fx::Statements)
    ActiveRecord::SchemaDumper.prepend(Fx::SchemaDumper)

    true
  end

  # @return [Fx::Configuration] F(x)'s current configuration
  def self.configuration
    @_configuration ||= Configuration.new
  end

  # Set F(x)'s configuration
  #
  # @param config [Fx::Configuration]
  def self.configuration=(config)
    @_configuration = config
  end

  # Modify F(x)'s current configuration
  #
  # @yieldparam [Fx::Configuration] config current F(x) config
  # ```
  # Fx.configure do |config|
  #   config.database = Fx::Adapters::Postgres
  #   config.dump_functions_at_beginning_of_schema = true
  # end
  # ```
  def self.configure
    yield configuration
  end

  # The current database adapter used by F(x).
  #
  # This defaults to {Fx::Adapters::Postgres} but can be overridden
  # via {Configuration}.
  def self.database
    configuration.database
  end
end
