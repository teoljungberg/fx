require "rails"
require "fx/schema/statements/function"
require "fx/schema/statements/trigger"

module Fx
  # @api private
  module Schema
    # @api private
    module Statements
      include Function
      include Trigger
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send(
  :include,
  Fx::Schema::Statements,
)
