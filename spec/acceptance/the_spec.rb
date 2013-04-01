require 'spec_helper'
require 'tempfile'
require 'fileutils'

describe "Vigil" do

  def in_test_project
    rcfile = Tempfile.new('vigil')
    Dir.mktmpdir do |test_repo_dir|
      Dir.mktmpdir do |run_dir|
        Vigil.run_dir = run_dir
        rcfile.write(<<EOF)
[projects]
[projects.test]
url = "#{test_repo_dir}"
type = "gem"
EOF
        rcfile.close
        git = Vigil::Git.new(git_dir: File.join(test_repo_dir, '.git'), work_tree: test_repo_dir)
        git.cmd("init")
        FileUtils.touch(File.join(test_repo_dir, 'README'))
        File.write(File.join(test_repo_dir, 'Rakefile'), "task(:default) {true}")
        git.cmd("add .")
        git.cmd('commit -m "commit message goes here"')
        yield(rcfile, run_dir)
      end
    end
  end
  
  it do
    cwd = Dir.pwd
    in_test_project do |rcfile, run_dir|
      v = Vigil.new(loop: ->(&b){b.call}, rcfile: rcfile)
      v.run
      Dir.chdir(cwd) # FIXME
      #p Dir.entries(run_dir)
      Dir.entries(File.join(run_dir, 'test')).should include('1', 'repo.git')
      Dir.entries(File.join(run_dir, 'test', 'repo.git')).should include('objects') #FIXME isa git repo
      Dir.entries(File.join(run_dir, 'test', '1')).should include('README', 'Rakefile')
    end
  end
end


