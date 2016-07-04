require "fx/version"
require "fx/adapters/postgres"
require "fx/command_recorder"
require "fx/configuration"
require "fx/definition"
require "fx/function"
require "fx/schema/statements"
require "fx/schema_dumper"
require "fx/trigger"

module Fx
  def self.database
    configuration.database
  end
end
