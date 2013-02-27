require 'vigil'

describe Vigil do

  it do
    shell = double('shell')
    vigil = Vigil.new(shell)

    shell.should_receive('_system').with("git clone /Users/kjellm/projects/amedia/znork/ .").ordered
    shell.should_receive('_system').with("git checkout vigil").ordered
    shell.should_receive('_system').with("ln -s /Users/kjellm/projects/vigil/run/iso").ordered
    shell.should_receive('_system').with("vagrant basebox build --force --nogui 'znork'").ordered
    shell.should_receive('_system').with("vagrant basebox validate 'znork'").ordered
    shell.should_receive('_system').with("vagrant basebox export 'znork'").ordered
    shell.should_receive('_system').with("mv znork.box /Users/kjellm/projects/vigil/run/znork/boxes/znork-1.box").ordered
    shell.should_receive('_system').with("vagrant basebox destroy znork").ordered
    shell.should_receive('_system').with("vagrant box add --force 'znork-1' '/Users/kjellm/projects/vigil/run/znork/boxes/znork-1.box'").ordered
    shell.should_receive('_system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1\\"")' Vagrantfile}).ordered
    shell.should_receive('_system').with("vagrant up").ordered
    shell.should_receive('_system').with("vagrant package --output /Users/kjellm/projects/vigil/run/znork/boxes/znork-1_no_gems.pkg").ordered
    shell.should_receive('_system').with("vagrant box remove znork-1").ordered
    shell.should_receive('_system').with("vagrant box add --force 'znork-1_no_gems' '/Users/kjellm/projects/vigil/run/znork/boxes/znork-1_no_gems.pkg'").ordered
    shell.should_receive('_system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1_no_gems\\"")' Vagrantfile}).ordered
    shell.should_receive('_system').with("vagrant up").ordered
    shell.should_receive('_system').with("vagrant ssh -c 'sudo gem install bundler'").ordered
    shell.should_receive('_system').with("vagrant ssh -c 'cd /vagrant/; bundle install'").ordered
    shell.should_receive('_system').with("vagrant package --output /Users/kjellm/projects/vigil/run/znork/boxes/znork-1_complete.pkg").ordered
    shell.should_receive('_system').with("vagrant box remove 'znork-1_no_gems'").ordered
    shell.should_receive('_system').with("vagrant box add --force 'znork-1_complete' '/Users/kjellm/projects/vigil/run/znork/boxes/znork-1_complete.pkg'").ordered
    shell.should_receive('_system').with(%Q{ruby -pi -e 'sub(/(config.vm.box = )"[^"]+"/, "\\\\1\\"znork-1_complete\\"")' Vagrantfile}).ordered
    shell.should_receive('_system').with("vagrant up").ordered
    shell.should_receive('_system').with("vagrant ssh -c 'cd /vagrant; rake test'").ordered
    
    vigil.run('1')
  end

end
