require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"

Rake::Task["release"].enhance do
  unless system("which gh > /dev/null 2>&1")
    abort "gh CLI is not installed. Install it to create GitHub releases."
  end

  tag = "v#{Fx::VERSION}"
  sh "gh release create #{tag} --verify-tag -t #{tag} --generate-notes"
end

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

desc "Run the specs and acceptance tests"
task default: %w[spec spec:acceptance standard]
