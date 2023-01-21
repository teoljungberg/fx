require File.expand_path("../boot", __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"

Bundler.require(*Rails.groups)
require "fx"

module Dummy
  class Application < Rails::Application
    config.cache_classes = true
    config.eager_load = false
    config.active_support.deprecation = :stderr

    if Rails.gem_version >= Gem::Version.new("6.1") && Rails.gem_version <= Gem::Version.new("7.0")
      config.active_record.legacy_connection_handling = false
    end
  end
end
