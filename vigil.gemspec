# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)
require "vigil/version"

Gem::Specification.new do |s|

  s.required_ruby_version     = '>= 1.9.3'

  s.name        = 'vigil'
  s.version     = Vigil::VERSION
  s.summary     = 'A continous deploy pipeline.'
  s.description = 'A continous deploy pipeline.'
  s.homepage    = 'http://github.com/kjellm/vigil'
  s.author      = 'Kjell-Magne Øierud'
  s.email       = 'kjellm@oierud.net'

  s.add_dependency("vagrant")
  s.add_dependency("veewee")
  s.add_dependency("trollop")
  s.add_dependency("plugman")

  s.files =  Dir.glob('bin/*') + 
    Dir.glob('lib/**/*.rb') + 
    Dir.glob('spec/**/*.rb') + 
    %w(CHANGES Gemfile README.md Rakefile)
  s.bindir = 'bin'
  s.executables = %w(vigil)

end

