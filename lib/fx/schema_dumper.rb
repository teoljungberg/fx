require "fx/schema_dumper/function"
require "fx/schema_dumper/trigger"
require "fx/schema_dumper/view"

module Fx
  # @api private
  module SchemaDumper
    include Function
    include Trigger
    include View
  end
end
