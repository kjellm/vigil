require 'tempfile'

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'vigil'

Vigil.logger = Logger.new(File.join(File.dirname(__FILE__), '../tmp/acceptance.log'))

Around do |scenario, block|
  $rcfile = Tempfile.new('vigil')
  cwd = Dir.pwd
  Dir.mktmpdir do |test_repo_dir|
    Dir.mktmpdir do |run_dir|
      Vigil.run_dir = run_dir
      $test_repo_dir = test_repo_dir
      $run_dir = run_dir
      write_rcfile($rcfile, test_repo_dir)
      $rcfile.close
      block.call
    end
  end
  Dir.chdir(cwd) # FIXME should not need to reset cwd here
end

def write_rcfile(io, test_repo_dir)
  io.write(<<EOF)
[projects]
[projects.test]
url = "#{test_repo_dir}"
type = "gem"
EOF
end

def git
  @git ||= Vigil::Git.new(git_dir: File.join($test_repo_dir, '.git'), work_tree: $test_repo_dir)
end

Given(/^a minimal git repository$/) do
  git.cmd("init")
  git.cmd('config user.email "you@example.com"')
  git.cmd('config user.name "Your Name"')
  File.write(File.join($test_repo_dir, 'Rakefile'), "task(:default) {true}")
  File.write(File.join($test_repo_dir, 'Gemfile'), "source 'https://rubygems.org'\ngem 'rake'")
  git.cmd("add .")
  git.cmd('commit -m "commit message goes here"')
end

When(/^Vigil runs$/) do
  @v = Vigil.new(loop: ->(&b){b.call}, rcfile: $rcfile)
  @v.start
end

Then(/^Vigil should do a first build$/) do
  Dir.entries(File.join($run_dir, 'test')).should include('1', 'repo.git')
  Dir.entries(File.join($run_dir, 'test', 'repo.git')).should include('objects') #FIXME isa git repo
  Dir.entries(File.join($run_dir, 'test', '1')).should include('Rakefile', '.vigil.yml')
end

When(/^Vigil runs and there are no changes since last run$/) do
  @v = Vigil.new(loop: ->(&b){b.call}, rcfile: $rcfile)
  @v.start
  @v.start
end

Then(/^Vigil should do nothing$/) do
  Dir.entries(File.join($run_dir, 'test')).should_not include('2')
end

When(/^a change is commited$/) do
  File.write(File.join($test_repo_dir, 'README.md'), "Hello World!\n")
  git.cmd("add .")
  git.cmd('commit -m "commit message goes here"')
end

When(/^Vigil runs again$/) do
  @v.start
end

Then(/^Vigil should do a new build$/) do
  Dir.entries(File.join($run_dir, 'test')).should include('1', '2', 'repo.git')
  Dir.entries(File.join($run_dir, 'test', '2')).should include('Rakefile', 'README.md', '.vigil.yml')
end
