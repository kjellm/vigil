require 'rspec/core/rake_task'
require 'bundler/gem_tasks'

desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new

desc "Test coverage"
task :cov do
  ENV["COVERAGE"] = 'true'
  sh "rspec spec/lib"
end
