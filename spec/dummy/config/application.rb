require File.expand_path("../boot", __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"

Bundler.require(*Rails.groups)
require "fx"

# Conditionally set table_name_prefix and/or table_name_suffix
TABLE_NAME_PREFIX = ENV["TABLE_NAME_PREFIX"].presence
TABLE_NAME_SUFFIX = ENV["TABLE_NAME_SUFFIX"].presence

module Dummy
  class Application < Rails::Application
    config.cache_classes = true
    config.eager_load = false
    config.active_support.deprecation = :stderr

    if TABLE_NAME_PREFIX
      $stdout.puts "Using table_name_prefix = '#{TABLE_NAME_PREFIX}'"
      config.active_record.table_name_prefix = TABLE_NAME_PREFIX
    end

    if TABLE_NAME_SUFFIX
      $stdout.puts "Using table_name_suffix = '#{TABLE_NAME_SUFFIX}'"
      config.active_record.table_name_suffix = TABLE_NAME_SUFFIX
    end
  end
end
