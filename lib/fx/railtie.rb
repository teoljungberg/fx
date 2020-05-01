require "rails/railtie"

module Fx
  # Automatically initializes Fx in the context of a Rails application when
  # ActiveRecord is loaded.
  #
  # @see Fx.load
  class Railtie < Rails::Railtie
    initializer "fx.load" do
      ActiveSupport.on_load :active_record do
        Fx.load
      end
    end
  end
end
