require "rails"
require "fx/statements/aggregate"
require "fx/statements/function"
require "fx/statements/trigger"

module Fx
  # @api private
  module Statements
    include Aggregate
    include Function
    include Trigger
  end
end
