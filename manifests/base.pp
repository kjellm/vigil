class ruby {
  
  $home = '/home/vagrant'
  $user = 'vagrant'
  $ruby = 'ruby-1.9.3-p392'
  $rvm_version = '1.19.1'
  
  Exec {
    logoutput => true,
    path      => ["$home/.rvm/bin", "/bin/", "/sbin/", "/usr/bin", "/usr/sbin"],
    user        => $user,
    environment => "HOME=$home",
  }

  # List taken from running 'rvm requirements'
  $rvm_requirements = [ "bash", "curl", "git", "patch" ]                       
  
  package {
    $rvm_requirements:
      ensure => installed,
  }
  
  exec {
    "rvm":
      command => "curl -s -L get.rvm.io | bash -s $rvm_version --autolibs=enabled",
      require => Package[$rvm_requirements],
      unless  => "test -d $home/.rvm",
  }

  exec {
    "ruby":
      command     => "bash -l -c 'rvm install $ruby'",
      timeout     => 3600,
      require     => Exec["rvm"],
      unless      => "test -d $home/.rvm/rubies/$ruby/",
  }
  exec {
    "use-ruby":
      command     => "bash -l -c 'rvm use --default $ruby'",
      require     => Exec["ruby"],
      unless      => "bash -l -c 'ruby -v' | grep '1.9.3p392'", # FIXME
  }
}

include ruby

package { 
  "libzmq-dev":
    ensure => installed,
}

package {
  "redis-server":
    ensure => installed,
}
service {
  "redis-server":
    ensure => running,
    require => Package["redis-server"],
}
