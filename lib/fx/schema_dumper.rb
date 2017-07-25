require "fx/schema_dumper/aggregate"
require "fx/schema_dumper/function"
require "fx/schema_dumper/trigger"

module Fx
  # @api private
  module SchemaDumper
    include Aggregate
    include Function
    include Trigger
  end
end

ActiveRecord::SchemaDumper.send(
  :prepend,
  Fx::SchemaDumper,
)
