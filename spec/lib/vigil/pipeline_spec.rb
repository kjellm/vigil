require 'spec_helper'

class Vigil
  describe Pipeline do

    describe "#run" do
      it "clones the repository, runs the VMBuilder, starts the VM, and runs tests" do
        Pipeline.any_instance.stub(:_redirected) {|&block| block.call }
        @os = double('os')
        @sys = double('system')
        Vigil.os = @os
        Vigil.run_dir = "/run"
        Vigil.plugman = double('plugman').as_null_object
        revision = Revision.new(1, Project.new(name: 'znork', os: @os, git_url: '/foo/bar/znork/', branch: 'master'))
        session = Session.new(revision: revision, plugman: Vigil.plugman, system: @sys)

        start_complete_box_expectations
        run_tests_expectation
        vmbuilder = double('vmbuilder')
        vmbuilder.should_receive('run')
        Pipeline.new(session, vmbuilder: vmbuilder).run
      end
    end
  
    def start_complete_box_expectations
      expect_command(%w(vagrant box add --force znork-1_complete /run/znork/boxes/znork-1_complete.pkg))
      expect_command(['ruby', '-pi', '-e', %Q{sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1_complete\\"")}, 'Vagrantfile'])
      expect_command(%w(vagrant up))
    end
  
    def run_tests_expectation
      @os.should_receive('system').with(*['vagrant', 'ssh', '-c', 'cd /vagrant; rake']).ordered
    end

    def expect_command(args)
      @sys.should_receive('run_command').with(args).ordered.and_return(double('res', status: true))
    end
  

  end
end
