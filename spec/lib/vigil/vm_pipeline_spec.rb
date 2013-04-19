require 'spec_helper'

class Vigil
  describe VMPipeline do

    describe "#run" do
      it "clones the repository, runs the VMBuilder, starts the VM, and runs tests" do
        @sys = double('system')
        plugman = double('plugman').as_null_object
        revision = double('revision',
          project_name: 'znork',
          complete_box_path: '/the/complete/box',
          complete_box_name: 'the_box')
        session = Session.new(env: double('env'), revision: revision, plugman: plugman, system: @sys)
        vmbuilder = double('vmbuilder')
        vmbuilder.should_receive('run')

        expect_command(%w(vagrant box add --force the_box /the/complete/box))
        expect_command(['ruby', '-pi', '-e', %Q{sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"the_box\\"")}, 'Vagrantfile'])
        expect_command(%w(vagrant up))
        expect_command(['vagrant', 'ssh', '-c', 'cd /vagrant; bundle exec rake'])

        VMPipeline.new(session, vmbuilder: vmbuilder).run
      end
    end
  
    def expect_command(args)
      @sys.should_receive('run_command').with(args).ordered.and_return(double('res', status: true))
    end

  end
end
