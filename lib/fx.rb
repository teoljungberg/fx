require "fx/version"
require "fx/adapters/postgres"
require "fx/schema/statements"
require "fx/command_recorder"
require "fx/definition"
require "fx/function"
require "fx/schema_dumper"

module Fx
  def self.database
    Fx::Adapters::Postgres
  end
end
