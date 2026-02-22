lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fx/version"

Gem::Specification.new do |spec|
  spec.name = "fx"
  spec.version = Fx::VERSION
  spec.authors = ["Teo Ljungberg"]
  spec.email = ["teo@teoljungberg.com"]
  spec.summary = "Support for database functions and triggers in Rails migrations"
  spec.description = <<~DESCRIPTION
    Adds methods to ActiveRecord::Migration to create and manage database functions
    and triggers in Rails
  DESCRIPTION
  spec.homepage = "https://github.com/teoljungberg/fx"
  spec.license = "MIT"
  spec.metadata = {
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "changelog_uri" => "#{spec.homepage}/blob/v#{spec.version}/CHANGELOG.md",
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage
  }

  spec.files = `git ls-files -z`.split("\x0")
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7.2"
  spec.add_dependency "railties", ">= 7.2"

  spec.required_ruby_version = ">= 3.2"
end
