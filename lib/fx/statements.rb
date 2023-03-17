require "rails"
require "fx/statements/function"
require "fx/statements/trigger"
require "fx/statements/view"

module Fx
  # @api private
  module Statements
    include Function
    include Trigger
    include View
  end
end
