require "fx/schema_dumper/function"
require "fx/schema_dumper/trigger"

module Fx
  # @api private
  module SchemaDumper
    include Function
    include Trigger
  end
end
