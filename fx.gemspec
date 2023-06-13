lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fx/version"

Gem::Specification.new do |spec|
  spec.name = "fx"
  spec.version = Fx::VERSION
  spec.authors = ["Teo Ljungberg"]
  spec.email = ["teo@teoljungberg.com"]
  spec.summary = "Support for database functions and triggers in Rails migrations"
  spec.description = <<-DESCRIPTION
    Adds methods to ActiveRecord::Migration to create and manage database functions
    and triggers in Rails
  DESCRIPTION
  spec.homepage = "https://github.com/teoljungberg/fx"
  spec.license = "MIT"
  spec.metadata = {
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "changelog_uri" => "#{spec.homepage}/blob/v#{spec.version}/CHANGELOG.md",
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,    
  }

  spec.files = `git ls-files -z`.split("\x0")
  spec.require_paths = ["lib"]

  spec.add_development_dependency "ammeter", ">= 1.1.3"
  spec.add_development_dependency "bundler", ">= 1.5"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "redcarpet"
  spec.add_development_dependency "rspec", ">= 3.3"
  spec.add_development_dependency "standardrb"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "warning"

  spec.add_dependency "activerecord", ">= 6.1"
  spec.add_dependency "railties", ">= 6.1"

  spec.required_ruby_version = ">= 3.0"
end
