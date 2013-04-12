require 'spec_helper'

class Vigil
  describe Pipeline do

    describe "#run" do
      it "clones the repository, runs the VMBuilder, starts the VM, and runs tests" do
        Pipeline.any_instance.stub(:_redirected) {|&block| block.call }
        @os = double('os')
        Vigil.os = @os
        Vigil.run_dir = "/run"
        Vigil.plugman = double('plugman').as_null_object
        revision = Revision.new(1, Project.new(name: 'znork', os: @os, git_url: '/foo/bar/znork/', branch: 'master'))

        start_complete_box_expectations
        run_tests_expectation
        vmbuilder = double('vmbuilder')
        vmbuilder.should_receive('run')
        Pipeline.new(revision, vmbuilder: vmbuilder).run
      end
    end
  
    def start_complete_box_expectations
      @os.should_receive('system').with("vagrant box add --force 'znork-1_complete' '/run/znork/boxes/znork-1_complete.pkg'").ordered
      @os.should_receive('system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1_complete\\"")' Vagrantfile}).ordered
      @os.should_receive('system').with("vagrant up").ordered
    end
  
    def run_tests_expectation
      @os.should_receive('system').with("vagrant ssh -c 'cd /vagrant; rake test'").ordered
    end
  end
end
