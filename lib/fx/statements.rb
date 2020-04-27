require "rails"
require "fx/statements/function"
require "fx/statements/trigger"

module Fx
  # @api private
  module Statements
    include Function
    include Trigger
  end
end
