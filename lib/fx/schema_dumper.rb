require "fx/schema_dumper/aggregate"
require "fx/schema_dumper/function"
require "fx/schema_dumper/trigger"

module Fx
  # @api private
  module SchemaDumper
    include Function
    include Aggregate # Aggregates _must_ be exported after Functions
    include Trigger
  end
end
