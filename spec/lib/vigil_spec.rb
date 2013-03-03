require 'vigil'

describe Vigil do

  before :each do
    @base = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

    @os = double('os')
    @vigil = Vigil.new(os: @os)
  
    @os.stub(mkdir_p: true)
    @os.should_receive('chdir').with("#@base/run/znork/1").ordered
    @os.should_receive('exists?').with("#@base/run/znork/1/.git").ordered
    @os.should_receive('_system').with("git clone /foo/bar/znork/ .").ordered
    @os.should_receive('_system').with("git checkout vigil").ordered
  end

  after :each do
    start_complete_box_expectations
    run_tests_expectation
    @vigil.run('/foo/bar/znork/', '1')
  end

  context "When the VM has already been built" do
    it "uses the already built VM" do
      @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-1_complete.pkg").ordered.and_return(true)
    end
  end

  context "When no VM has been built before" do
    it "builds a VM from scratch" do
      @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-1_complete.pkg").and_return(false)

      @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-1.box").and_return(false)
      @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-0.box").and_return(false)
      @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-1_no_gems.pkg").and_return(false)

      basebox_expectations
      no_gems_box_expectations
      complete_box_expectations
    end
  end

  context "When a VM has been completely built for the previous revision" do
    before :each do
      @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-1_complete.pkg").and_return(false)
    end

    context "and none of the VM configuration files has changed" do
      it "reuses the VM" do
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-0.box").and_return(true)
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-0_no_gems.pkg").and_return(true)
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-0_complete.pkg").and_return(true)
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-1.box").and_return(false)
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-1_no_gems.pkg").and_return(false)

        @os.should_receive('__system').with("git diff --quiet HEAD^ -- definitions").and_return(true)
        @os.should_receive('__system').with("git diff --quiet HEAD^ -- manifests").and_return(true)
        @os.should_receive('__system').with("git diff --quiet HEAD^ -- Gemfile*").and_return(true)

        @os.should_receive('ln').with("#@base/run/znork/boxes/znork-0.box", "#@base/run/znork/boxes/znork-1.box").ordered
        @os.should_receive('ln').with("#@base/run/znork/boxes/znork-0_no_gems.pkg", "#@base/run/znork/boxes/znork-1_no_gems.pkg").ordered
        @os.should_receive('ln').with("#@base/run/znork/boxes/znork-0_complete.pkg", "#@base/run/znork/boxes/znork-1_complete.pkg").ordered
      end
    end

    context "and only the veewee definitions has changed" do
      it "builds the VM from scratch" do
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-0.box").and_return(true)
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-1.box").and_return(false)
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-1_no_gems.pkg").and_return(false)

        @os.should_receive('__system').with("git diff --quiet HEAD^ -- definitions").and_return(false)

        basebox_expectations
        no_gems_box_expectations
        complete_box_expectations
      end
    end

    context "and only the puppet manifests has changed" do
      it "uses the previous revisions basebox to build the VM" do
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-0.box").and_return(true)
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-0_no_gems.pkg").and_return(true)
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-1.box").and_return(false)
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-1_no_gems.pkg").and_return(false)

        @os.should_receive('__system').with("git diff --quiet HEAD^ -- definitions").and_return(true)
        @os.should_receive('__system').with("git diff --quiet HEAD^ -- manifests").and_return(false)

        @os.should_receive('ln').with("#@base/run/znork/boxes/znork-0.box", "#@base/run/znork/boxes/znork-1.box").ordered
        no_gems_box_expectations
        complete_box_expectations
      end
    end

    context "and only Gemfile* has changed" do
      it "uses the previous revisions basebox to build the VM" do
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-0.box").and_return(true)
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-0_complete.pkg").and_return(true)
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-0_no_gems.pkg").and_return(true)
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-1.box").and_return(false)
        @os.should_receive('exists?').with("#@base/run/znork/boxes/znork-1_no_gems.pkg").and_return(false)

        @os.should_receive('__system').with("git diff --quiet HEAD^ -- definitions").and_return(true)
        @os.should_receive('__system').with("git diff --quiet HEAD^ -- manifests").and_return(true)
        @os.should_receive('__system').with("git diff --quiet HEAD^ -- Gemfile*").and_return(false)

        @os.should_receive('ln').with("#@base/run/znork/boxes/znork-0.box", "#@base/run/znork/boxes/znork-1.box").ordered
        @os.should_receive('ln').with("#@base/run/znork/boxes/znork-0_no_gems.pkg", "#@base/run/znork/boxes/znork-1_no_gems.pkg").ordered
 
        complete_box_expectations
      end
    end
  end

  def basebox_expectations
    @os.should_receive('_system').with("ln -sf #@base/run/iso").ordered
    @os.should_receive('_system').with("vagrant basebox build --force --nogui 'znork'").ordered
    @os.should_receive('_system').with("vagrant basebox validate 'znork'").ordered
    @os.should_receive('_system').with("vagrant basebox export 'znork'").ordered
    @os.should_receive('_system').with("mv znork.box #@base/run/znork/boxes/znork-1.box").ordered
    @os.should_receive('_system').with("vagrant basebox destroy znork").ordered
  end

  def no_gems_box_expectations
    @os.should_receive('_system').with("vagrant box add --force 'znork-1' '#@base/run/znork/boxes/znork-1.box'").ordered
    @os.should_receive('_system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1\\"")' Vagrantfile}).ordered
    @os.should_receive('_system').with("vagrant up").ordered
    @os.should_receive('_system').with("vagrant package --output #@base/run/znork/boxes/znork-1_no_gems.pkg").ordered
    @os.should_receive('_system').with("vagrant box remove znork-1").ordered
  end

  def complete_box_expectations
    @os.should_receive('_system').with("vagrant box add --force 'znork-1_no_gems' '#@base/run/znork/boxes/znork-1_no_gems.pkg'").ordered
    @os.should_receive('_system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1_no_gems\\"")' Vagrantfile}).ordered
    @os.should_receive('_system').with("vagrant up").ordered
    @os.should_receive('_system').with("vagrant ssh -c 'sudo gem install bundler'").ordered
    @os.should_receive('_system').with("vagrant ssh -c 'cd /vagrant/; bundle install'").ordered
    @os.should_receive('_system').with("vagrant package --output #@base/run/znork/boxes/znork-1_complete.pkg").ordered
    @os.should_receive('_system').with("vagrant box remove 'znork-1_no_gems'").ordered
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
