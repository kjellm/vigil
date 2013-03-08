require 'spec_helper'

class Vigil
  describe Pipeline do

    describe "#run" do
      it "clones the repository, runs the VMBuilder, starts the VM, and runs tests" do
        @os = double('os')
        Vigil.os = @os
        Vigil.run_dir = "/run"
        Vigil.plugman = double('plugman').as_null_object
        @os.should_receive('chdir').with("/run/znork/1").ordered
        revision = Revision.new(1, Project.new(name: 'znork', os: @os, git_url: '/foo/bar/znork/', branch: 'master'))

        git_clone_expectations
        start_complete_box_expectations
        run_tests_expectation
        vmbuilder = double('vmbuilder')
        vmbuilder.should_receive('run')
        Pipeline.new(revision, vmbuilder: vmbuilder).run
      end
    end
  
    def git_clone_expectations
      @os.should_receive('exists?').with("/run/znork/1/.git").ordered
      @os.should_receive('_system').with("git clone /foo/bar/znork/ .").ordered
      @os.should_receive('_system').with("git checkout master").ordered
    end

    def start_complete_box_expectations
      @os.should_receive('_system').with("vagrant box add --force 'znork-1_complete' '/run/znork/boxes/znork-1_complete.pkg'").ordered
      @os.should_receive('_system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1_complete\\"")' Vagrantfile}).ordered
      @os.should_receive('_system').with("vagrant up").ordered
    end
  
    def run_tests_expectation
      @os.should_receive('_system').with("vagrant ssh -c 'cd /vagrant; rake test'").ordered
    end
  end
end
