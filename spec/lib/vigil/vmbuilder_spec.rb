require 'spec_helper'

class Vigil
  describe VMBuilder do

    before :each do
      @os = double('os')
      Vigil.os = @os
      Vigil.run_dir = "/run"
    end
  
    after :each do
      revision = Revision.new(1, Project.new(name: 'znork', os: @os, run_dir: "/run", git_url: '/foo/bar/znork/', branch: 'master'))
      VMBuilder.new(Vagrant.new(@os), revision).run
    end
  
    context "When the VM has already been built" do
      it "uses the already built VM" do
        @os.should_receive('exists?').with("/run/znork/boxes/znork-1_complete.pkg").ordered.and_return(true)
      end
    end
  
    context "When no VM has been built before" do
      it "builds a VM from scratch" do
        @os.should_receive('exists?').with("/run/znork/boxes/znork-1_complete.pkg").and_return(false)
  
        @os.should_receive('exists?').with("/run/znork/boxes/znork-1.box").and_return(false)
        @os.should_receive('exists?').with("/run/znork/boxes/znork-0.box").and_return(false)
        @os.should_receive('exists?').with("/run/znork/boxes/znork-1_no_gems.pkg").and_return(false)
  
        basebox_expectations
        no_gems_box_expectations
        complete_box_expectations
      end
    end
  
    context "When a VM has been completely built for the previous revision" do
      before :each do
        @os.should_receive('exists?').with("/run/znork/boxes/znork-1_complete.pkg").and_return(false)
      end
  
      context "and none of the VM configuration files has changed" do
        it "reuses the VM" do
          @os.should_receive('exists?').with("/run/znork/boxes/znork-0.box").and_return(true)
          @os.should_receive('exists?').with("/run/znork/boxes/znork-0_no_gems.pkg").and_return(true)
          @os.should_receive('exists?').with("/run/znork/boxes/znork-0_complete.pkg").and_return(true)
          @os.should_receive('exists?').with("/run/znork/boxes/znork-1.box").and_return(false)
          @os.should_receive('exists?').with("/run/znork/boxes/znork-1_no_gems.pkg").and_return(false)
  
          @os.should_receive('__system').with("git diff --quiet HEAD^ -- definitions").and_return(true)
          @os.should_receive('__system').with("git diff --quiet HEAD^ -- manifests").and_return(true)
          @os.should_receive('__system').with("git diff --quiet HEAD^ -- Gemfile*").and_return(true)
  
          @os.should_receive('ln').with("/run/znork/boxes/znork-0.box", "/run/znork/boxes/znork-1.box").ordered
          @os.should_receive('ln').with("/run/znork/boxes/znork-0_no_gems.pkg", "/run/znork/boxes/znork-1_no_gems.pkg").ordered
          @os.should_receive('ln').with("/run/znork/boxes/znork-0_complete.pkg", "/run/znork/boxes/znork-1_complete.pkg").ordered
        end
      end
  
      context "and only the veewee definitions has changed" do
        it "builds the VM from scratch" do
          @os.should_receive('exists?').with("/run/znork/boxes/znork-0.box").and_return(true)
          @os.should_receive('exists?').with("/run/znork/boxes/znork-1.box").and_return(false)
          @os.should_receive('exists?').with("/run/znork/boxes/znork-1_no_gems.pkg").and_return(false)
  
          @os.should_receive('__system').with("git diff --quiet HEAD^ -- definitions").and_return(false)
  
          basebox_expectations
          no_gems_box_expectations
          complete_box_expectations
        end
      end
  
      context "and only the puppet manifests has changed" do
        it "uses the previous revisions basebox to build the VM" do
          @os.should_receive('exists?').with("/run/znork/boxes/znork-0.box").and_return(true)
          @os.should_receive('exists?').with("/run/znork/boxes/znork-0_no_gems.pkg").and_return(true)
          @os.should_receive('exists?').with("/run/znork/boxes/znork-1.box").and_return(false)
          @os.should_receive('exists?').with("/run/znork/boxes/znork-1_no_gems.pkg").and_return(false)
  
          @os.should_receive('__system').with("git diff --quiet HEAD^ -- definitions").and_return(true)
          @os.should_receive('__system').with("git diff --quiet HEAD^ -- manifests").and_return(false)
  
          @os.should_receive('ln').with("/run/znork/boxes/znork-0.box", "/run/znork/boxes/znork-1.box").ordered
          no_gems_box_expectations
          complete_box_expectations
        end
      end
  
      context "and only Gemfile* has changed" do
        it "uses the previous revisions basebox to build the VM" do
          @os.should_receive('exists?').with("/run/znork/boxes/znork-0.box").and_return(true)
          @os.should_receive('exists?').with("/run/znork/boxes/znork-0_complete.pkg").and_return(true)
          @os.should_receive('exists?').with("/run/znork/boxes/znork-0_no_gems.pkg").and_return(true)
          @os.should_receive('exists?').with("/run/znork/boxes/znork-1.box").and_return(false)
          @os.should_receive('exists?').with("/run/znork/boxes/znork-1_no_gems.pkg").and_return(false)
  
          @os.should_receive('__system').with("git diff --quiet HEAD^ -- definitions").and_return(true)
          @os.should_receive('__system').with("git diff --quiet HEAD^ -- manifests").and_return(true)
          @os.should_receive('__system').with("git diff --quiet HEAD^ -- Gemfile*").and_return(false)
  
          @os.should_receive('ln').with("/run/znork/boxes/znork-0.box", "/run/znork/boxes/znork-1.box").ordered
          @os.should_receive('ln').with("/run/znork/boxes/znork-0_no_gems.pkg", "/run/znork/boxes/znork-1_no_gems.pkg").ordered
   
          complete_box_expectations
        end
      end
    end
  
    def basebox_expectations
      @os.should_receive('_system').with("ln -sf /run/iso").ordered
      @os.should_receive('_system').with("vagrant basebox build --force --nogui 'znork'").ordered
      @os.should_receive('_system').with("vagrant basebox validate 'znork'").ordered
      @os.should_receive('_system').with("vagrant basebox export 'znork'").ordered
      @os.should_receive('_system').with("mv znork.box /run/znork/boxes/znork-1.box").ordered
      @os.should_receive('_system').with("vagrant basebox destroy znork").ordered
    end
  
    def no_gems_box_expectations
      @os.should_receive('_system').with("vagrant box add --force 'znork-1' '/run/znork/boxes/znork-1.box'").ordered
      @os.should_receive('_system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1\\"")' Vagrantfile}).ordered
      @os.should_receive('_system').with("vagrant up").ordered
      @os.should_receive('_system').with("vagrant package --output /run/znork/boxes/znork-1_no_gems.pkg").ordered
      @os.should_receive('_system').with("vagrant box remove znork-1").ordered
    end
  
    def complete_box_expectations
      @os.should_receive('_system').with("vagrant box add --force 'znork-1_no_gems' '/run/znork/boxes/znork-1_no_gems.pkg'").ordered
      @os.should_receive('_system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1_no_gems\\"")' Vagrantfile}).ordered
      @os.should_receive('_system').with("vagrant up").ordered
      @os.should_receive('_system').with("vagrant ssh -c 'sudo gem install bundler'").ordered
      @os.should_receive('_system').with("vagrant ssh -c 'cd /vagrant/; bundle install'").ordered
      @os.should_receive('_system').with("vagrant package --output /run/znork/boxes/znork-1_complete.pkg").ordered
      @os.should_receive('_system').with("vagrant box remove 'znork-1_no_gems'").ordered
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
