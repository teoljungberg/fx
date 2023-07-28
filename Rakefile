require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "syntax_tree/rake_tasks"

namespace :dummy do
  require_relative "spec/dummy/config/application"
  Dummy::Application.load_tasks
end

task(:spec).clear
desc "Run specs other than spec/acceptance"
RSpec::Core::RakeTask.new("spec") do |task|
  task.exclude_pattern = "spec/acceptance/**/*_spec.rb"
  task.verbose = false
end

desc "Run acceptance specs in spec/acceptance"
RSpec::Core::RakeTask.new("spec:acceptance") do |task|
  task.pattern = "spec/acceptance/**/*_spec.rb"
  task.verbose = false
end

desc "Check syntax with syntax_tree"
SyntaxTree::Rake::CheckTask.new do |task|
  task.source_files = "{lib,spec}/**/*.rb"
end

desc "Run the specs and acceptance tests"
task default: %w[spec spec:acceptance stree:check]
