require 'vigil'

describe Vigil do

  base = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

  before :each do
    @shell = double('shell')
    @vigil = Vigil.new(@shell)
  
    @shell.stub(mkdir_p: true)
  
    @shell.should_receive('chdir').with("#{base}/run/znork/1").ordered
  
    @shell.should_receive('_system').with("git clone /foo/bar/znork/ .").ordered
    @shell.should_receive('_system').with("git checkout vigil").ordered
    @shell.should_receive('_system').with("ln -s #{base}/run/iso").ordered
  end

  context "When no VM has been built before" do

    it "builds a VM from scratch" do
      @shell.should_receive('exists?').with("#{base}/run/znork/boxes/znork-1.box").ordered.and_return(false)
      @shell.should_receive('exists?').with("#{base}/run/znork/boxes/znork-0.box").ordered.and_return(false)
      @shell.should_receive('_system').with("vagrant basebox build --force --nogui 'znork'").ordered
      @shell.should_receive('_system').with("vagrant basebox validate 'znork'").ordered
      @shell.should_receive('_system').with("vagrant basebox export 'znork'").ordered
      @shell.should_receive('_system').with("mv znork.box #{base}/run/znork/boxes/znork-1.box").ordered
      @shell.should_receive('_system').with("vagrant basebox destroy znork").ordered
  
  
      @shell.should_receive('exists?').with("#{base}/run/znork/boxes/znork-1_no_gems.pkg").ordered.and_return(false)
      @shell.should_receive('exists?').with("#{base}/run/znork/boxes/znork-0_no_gems.pkg").ordered.and_return(false)
      @shell.should_receive('_system').with("vagrant box add --force 'znork-1' '#{base}/run/znork/boxes/znork-1.box'").ordered
      @shell.should_receive('_system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1\\"")' Vagrantfile}).ordered
      @shell.should_receive('_system').with("vagrant up").ordered
      @shell.should_receive('_system').with("vagrant package --output #{base}/run/znork/boxes/znork-1_no_gems.pkg").ordered
      @shell.should_receive('_system').with("vagrant box remove znork-1").ordered
  
  
      @shell.should_receive('exists?').with("#{base}/run/znork/boxes/znork-1_complete.pkg").ordered.and_return(false)
      @shell.should_receive('exists?').with("#{base}/run/znork/boxes/znork-0_complete.pkg").ordered.and_return(false)
      @shell.should_receive('_system').with("vagrant box add --force 'znork-1_no_gems' '#{base}/run/znork/boxes/znork-1_no_gems.pkg'").ordered
      @shell.should_receive('_system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1_no_gems\\"")' Vagrantfile}).ordered
      @shell.should_receive('_system').with("vagrant up").ordered
      @shell.should_receive('_system').with("vagrant ssh -c 'sudo gem install bundler'").ordered
      @shell.should_receive('_system').with("vagrant ssh -c 'cd /vagrant/; bundle install'").ordered
      @shell.should_receive('_system').with("vagrant package --output #{base}/run/znork/boxes/znork-1_complete.pkg").ordered
      @shell.should_receive('_system').with("vagrant box remove 'znork-1_no_gems'").ordered
  
  
      @shell.should_receive('_system').with("vagrant box add --force 'znork-1_complete' '#{base}/run/znork/boxes/znork-1_complete.pkg'").ordered
      @shell.should_receive('_system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1_complete\\"")' Vagrantfile}).ordered
      @shell.should_receive('_system').with("vagrant up").ordered
  
  
      @shell.should_receive('_system').with("vagrant ssh -c 'cd /vagrant; rake test'").ordered
      
  
      @vigil.run('/foo/bar/znork/', '1')
    end
  end

  context "When a VM has been previously been completely built for this revision" do

    it "uses the previously built VM" do
      @shell.should_receive('exists?').with("#{base}/run/znork/boxes/znork-1.box").ordered.and_return(true)
      @shell.should_receive('exists?').with("#{base}/run/znork/boxes/znork-1_no_gems.pkg").ordered.and_return(true)
      @shell.should_receive('exists?').with("#{base}/run/znork/boxes/znork-1_complete.pkg").ordered.and_return(true)

      @shell.should_receive('_system').with("vagrant box add --force 'znork-1_complete' '#{base}/run/znork/boxes/znork-1_complete.pkg'").ordered
      @shell.should_receive('_system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1_complete\\"")' Vagrantfile}).ordered
      @shell.should_receive('_system').with("vagrant up").ordered
  
      @shell.should_receive('_system').with("vagrant ssh -c 'cd /vagrant; rake test'").ordered

      @vigil.run('/foo/bar/znork/', '1')
    end
  end

  context "When a VM has been built for the previous revision" do

    xit "reuses the VM when none of the VM configuration files has changed" do
      @shell.should_receive('exists?').with("#{base}/run/znork/boxes/znork-1.box").ordered.and_return(false)
      @shell.should_receive('exists?').with("#{base}/run/znork/boxes/znork-0.box").ordered.and_return(true)
      @shell.should_receive('__system').with("git diff --quiet HEAD^ -- definitions").ordered.and_return(false)
  
      @shell.should_receive('exists?').with("#{base}/run/znork/boxes/znork-0_no_gems.pkg").ordered.and_return(false)
      @shell.should_receive('_system').with("vagrant box add --force 'znork-1' '#{base}/run/znork/boxes/znork-1.box'").ordered
      @shell.should_receive('_system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1\\"")' Vagrantfile}).ordered
      @shell.should_receive('_system').with("vagrant up").ordered
      @shell.should_receive('_system').with("vagrant package --output #{base}/run/znork/boxes/znork-1_no_gems.pkg").ordered
      @shell.should_receive('_system').with("vagrant box remove znork-1").ordered
  
  
      @shell.should_receive('exists?').with("#{base}/run/znork/boxes/znork-0_complete.pkg").ordered.and_return(false)
      @shell.should_receive('_system').with("vagrant box add --force 'znork-1_no_gems' '#{base}/run/znork/boxes/znork-1_no_gems.pkg'").ordered
      @shell.should_receive('_system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1_no_gems\\"")' Vagrantfile}).ordered
      @shell.should_receive('_system').with("vagrant up").ordered
      @shell.should_receive('_system').with("vagrant ssh -c 'sudo gem install bundler'").ordered
      @shell.should_receive('_system').with("vagrant ssh -c 'cd /vagrant/; bundle install'").ordered
      @shell.should_receive('_system').with("vagrant package --output #{base}/run/znork/boxes/znork-1_complete.pkg").ordered
      @shell.should_receive('_system').with("vagrant box remove 'znork-1_no_gems'").ordered
  
  
      @shell.should_receive('_system').with("vagrant box add --force 'znork-1_complete' '#{base}/run/znork/boxes/znork-1_complete.pkg'").ordered
      @shell.should_receive('_system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1_complete\\"")' Vagrantfile}).ordered
      @shell.should_receive('_system').with("vagrant up").ordered
  
  
      @shell.should_receive('_system').with("vagrant ssh -c 'cd /vagrant; rake test'").ordered
      
  
      @vigil.run('/foo/bar/znork/', '1')
    end
  end
end
