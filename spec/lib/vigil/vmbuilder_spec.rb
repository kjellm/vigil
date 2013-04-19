require 'spec_helper'

class Vigil

  describe VMBuilder do

    before :each do
      Revision.any_instance.stub(sha: 'the_sha')
      @os = double('os')
      Vigil.os = @os
      Vigil.run_dir = "/run"
      Vigil.plugman = double('plugman').as_null_object
      @sys = double('system')
      @os.should_receive('mkdir_p').with("/run/iso").ordered
      @os.should_receive('system').with("ln -sf /run/iso").ordered
    end
  
    after :each do
      project = Project.new(name: 'znork', os: @os, run_dir: "/run", git_url: '/foo/bar/znork/', branch: 'master')
      revision = Revision.new(1, project)
      session = Session.new(revision: revision, plugman: Vigil.plugman, system: @sys)
      VMBuilder.new(session).run
    end
  
    context "When the VM has already been built" do
      it "uses the already built VM" do
        @os.should_receive('exists?').with("/run/znork/boxes/znork-1_complete.pkg").ordered.and_return(true)
      end
    end
  
    context "When no VM has been built before" do
      it "builds a VM from scratch" do
        @os.stub('exists?', false)
        basebox_expectations
        no_gems_box_expectations
        complete_box_expectations
      end
    end
  
    context "When a VM has been completely built for the previous revision" do
      before :each do
          @os.stub('exists?') do |file|
            %w(/run/znork/boxes/znork-0.box
               /run/znork/boxes/znork-0_no_gems.pkg
               /run/znork/boxes/znork-0_complete.pkg).include? file
          end
      end
  
      context "and none of the VM configuration files has changed" do
        it "reuses the VM" do
          @os.should_receive('system').with("git diff --quiet the_sha -- definitions").and_return(true)
          @os.should_receive('system').with("git diff --quiet the_sha -- manifests").and_return(true)
          @os.should_receive('system').with("git diff --quiet the_sha -- Gemfile*").and_return(true)
  
          expect_command(%w(ln /run/znork/boxes/znork-0.box /run/znork/boxes/znork-1.box))
          expect_command(%w(ln /run/znork/boxes/znork-0_no_gems.pkg /run/znork/boxes/znork-1_no_gems.pkg))
          expect_command(%w(ln /run/znork/boxes/znork-0_complete.pkg /run/znork/boxes/znork-1_complete.pkg))
        end
      end
  
      context "and only the veewee definitions has changed" do
        it "builds the VM from scratch" do
          @os.should_receive('system').with("git diff --quiet the_sha -- definitions").and_return(false)
          basebox_expectations
          no_gems_box_expectations
          complete_box_expectations
        end
      end
  
      context "and only the puppet manifests has changed" do
        it "uses the previous revisions basebox to build the VM" do
          @os.should_receive('system').with("git diff --quiet the_sha -- definitions").and_return(true)
          @os.should_receive('system').with("git diff --quiet the_sha -- manifests").and_return(false)
          expect_command(%w(ln /run/znork/boxes/znork-0.box /run/znork/boxes/znork-1.box))
          no_gems_box_expectations
          complete_box_expectations
        end
      end
  
      context "and only Gemfile* has changed" do
        it "uses the previous revisions basebox to build the VM" do
          @os.should_receive('system').with("git diff --quiet the_sha -- definitions").and_return(true)
          @os.should_receive('system').with("git diff --quiet the_sha -- manifests").and_return(true)
          @os.should_receive('system').with("git diff --quiet the_sha -- Gemfile*").and_return(false)
          expect_command(%w(ln /run/znork/boxes/znork-0.box /run/znork/boxes/znork-1.box))
          expect_command(%w(ln /run/znork/boxes/znork-0_no_gems.pkg /run/znork/boxes/znork-1_no_gems.pkg))   
          complete_box_expectations
        end
      end
    end
  
    def basebox_expectations
      expect_command(%w(vagrant basebox build --force --nogui --redirect-console --auto znork))
      expect_command(%w(vagrant basebox validate znork))
      expect_command(%w(vagrant basebox export znork))
      expect_command(%w(mv znork.box /run/znork/boxes/znork-1.box))
      expect_command(%w(vagrant basebox destroy znork))
    end
  
    def no_gems_box_expectations
      expect_command(%w(vagrant box add --force znork-1 /run/znork/boxes/znork-1.box))
      expect_command(['ruby', '-pi', '-e', %Q{sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1\\"")}, 'Vagrantfile'])
      expect_command(%w(vagrant up))
      expect_command(%w(vagrant package --output /run/znork/boxes/znork-1_no_gems.pkg))
      expect_command(%w(vagrant box remove znork-1))
    end
  
    def complete_box_expectations
      ret = double('res', status: true)
      expect_command(%w(vagrant box add --force znork-1_no_gems /run/znork/boxes/znork-1_no_gems.pkg))
      expect_command(['ruby', '-pi', '-e', %Q{sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1_no_gems\\"")}, 'Vagrantfile'])
      expect_command(%w(vagrant up))
      expect_command(['vagrant', 'ssh', '-c', 'sudo gem install bundler'])
      expect_command(['vagrant', 'ssh', '-c', 'cd /vagrant/; bundle install'])
      expect_command(%w(vagrant package --output /run/znork/boxes/znork-1_complete.pkg))
      expect_command(%w(vagrant box remove znork-1_no_gems))
    end

    def expect_command(args)
      @sys.should_receive('run_command').with(args).ordered.and_return(double('res', status: true))
    end
  
  end
end
