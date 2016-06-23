require "fx/version"
require "fx/adapters/postgres"
require "fx/active_record/schema/statements"
require "fx/active_record/command_recorder"
require "fx/active_record/schema_dumper"

module Fx
  def self.database
    Fx::Adapters::Postgres
  end
end
