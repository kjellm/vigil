require 'spec_helper'
require 'tempfile'
require 'fileutils'

describe "Vigil" do

  def in_test_project
    rcfile = Tempfile.new('vigil')
    Dir.mktmpdir do |test_repo_dir|
      Dir.mktmpdir do |run_dir|
        Vigil.run_dir = run_dir
        write_rcfile(rcfile, test_repo_dir)
        rcfile.close
        a_minimal_git_repo(test_repo_dir)
        yield(rcfile, run_dir, test_repo_dir)
      end
    end
  end

  def write_rcfile(io, test_repo_dir)
    io.write(<<EOF)
[projects]
[projects.test]
url = "#{test_repo_dir}"
type = "gem"
EOF
  end

  def git(test_repo_dir=nil)
    @git ||= Vigil::Git.new(git_dir: File.join(test_repo_dir, '.git'), work_tree: test_repo_dir)
  end

  def a_minimal_git_repo(test_repo_dir)
    git(test_repo_dir)
    git.cmd("init")
    git.cmd('config user.email "you@example.com"')
    git.cmd('config user.name "Your Name"')
    File.write(File.join(test_repo_dir, 'Rakefile'), "task(:default) {true}")
    git.cmd("add .")
    git.cmd('commit -m "commit message goes here"')
  end
  
  it "" do
    cwd = Dir.pwd
    in_test_project do |rcfile, run_dir, _|
      begin
        v = Vigil.new(loop: ->(&b){b.call}, rcfile: rcfile)
        v.run
        Dir.entries(File.join(run_dir, 'test')).should include('1', 'repo.git')
        Dir.entries(File.join(run_dir, 'test', 'repo.git')).should include('objects') #FIXME isa git repo
        Dir.entries(File.join(run_dir, 'test', '1')).should include('Rakefile')
      ensure
        Dir.chdir(cwd) # FIXME should not need to reset cwd here
      end
    end
  end

  context "when there are no changes since last run" do
    it "does not start a new build" do
      cwd = Dir.pwd
      in_test_project do |rcfile, run_dir, _|
        begin
          v = Vigil.new(loop: ->(&b){b.call}, rcfile: rcfile)
          v.run
          v.run
          
          p Dir.pwd
          Dir.entries(File.join(run_dir, 'test')).should_not include('2')
        ensure
          Dir.chdir(cwd) # FIXME should not need to reset cwd here
        end
      end
    end
  end

  context "when there are changes since last run" do
    it "starts a new build" do
      cwd = Dir.pwd
      in_test_project do |rcfile, run_dir, test_repo_dir|
        begin
          v = Vigil.new(loop: ->(&b){b.call}, rcfile: rcfile)
          v.run

          File.write(File.join(test_repo_dir, 'README.md'), "Hello World!\n")
          git.cmd("add .")
          git.cmd('commit -m "commit message goes here"')
          v.run
      
          Dir.entries(File.join(run_dir, 'test')).should include('1', '2', 'repo.git')
          Dir.entries(File.join(run_dir, 'test', '2')).should include('Rakefile', 'README.md')
        ensure
          Dir.chdir(cwd) # FIXME should not need to reset cwd here
        end
      end
    end

  end
end
