require 'rspec/core/rake_task'
require 'bundler/gem_tasks'
require 'cucumber/rake/task'

desc 'Default: run specs.'
task :default => [:spec, :cucumber]

desc "Run specs"
RSpec::Core::RakeTask.new

desc "Run features"
Cucumber::Rake::Task.new

desc "Test coverage"
task :cov do
  ENV["COVERAGE"] = 'true'
  sh "rspec spec/lib"
end
