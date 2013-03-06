require 'spec_helper'

class Vigil
  describe Pipeline do

    it do
      @base = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
  
      @os = double('os')
      Vigil.os = @os
      @os.stub(mkdir_p: true)
      @os.should_receive('chdir').with("#@base/run/znork/1").ordered
      revision = Revision.new(1, Project.new(name: 'znork', os: @os, run_dir: "#@base/run", git_url: '/foo/bar/znork/', branch: 'master'))

      git_clone_expectations
      start_complete_box_expectations
      run_tests_expectation
      vmbuilder = double('vmbuilder')
      vmbuilder.should_receive('run')
      Pipeline.new(revision, vmbuilder: vmbuilder).run
    end
  
    def git_clone_expectations
      @os.should_receive('exists?').with("#@base/run/znork/1/.git").ordered
      @os.should_receive('_system').with("git clone /foo/bar/znork/ .").ordered
      @os.should_receive('_system').with("git checkout master").ordered
    end

    def start_complete_box_expectations
      @os.should_receive('_system').with("vagrant box add --force 'znork-1_complete' '#@base/run/znork/boxes/znork-1_complete.pkg'").ordered
      @os.should_receive('_system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1_complete\\"")' Vagrantfile}).ordered
      @os.should_receive('_system').with("vagrant up").ordered
    end
  
    def run_tests_expectation
      @os.should_receive('_system').with("vagrant ssh -c 'cd /vagrant; rake test'").ordered
    end
  end
end
