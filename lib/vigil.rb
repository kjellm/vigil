require 'plugman'
require 'vigil/git'
require 'vigil/os'
require 'vigil/pipeline'
require 'vigil/test_pipeline'
require 'vigil/project'
require 'vigil/revision'
require 'vigil/revision_repository'
require 'vigil/vagrant'
require 'vigil/vmbuilder'

class Vigil
  
  class << self
    attr :os, true
    attr :run_dir, true
    attr :plugman, true
  end

  def initialize(args)
    @x = args[:os] || Vigil::OS.new
    Vigil.os = @x
    Vigil.run_dir = File.expand_path 'run'
    Vigil.plugman = Plugman.new(plugins: [])
    _initialize_projects(args[:projects] || [])
  end
  
  def _initialize_projects(projects)
    @projects = projects.map do |p| 
      Project.new(
        name:    p[:name],
        git_url: p[:git][:url],
        branch:  p[:git][:branch]
      )
    end
  end
    
  def run
    @x.mkdir_p Vigil.run_dir
    loop do
      _less_often_than_every(60) do
        puts "### Vigil loop"
        @projects.each do |p|
          puts "## #{p.inspect}"
          p.run_pipeline
        end
      end
    end
  end

  def _less_often_than_every(n_seconds)
    start = Time.now
    yield
    _end = Time.now
    if _end - start < n_seconds
      n = n_seconds - (_end - start)
      puts "Sleeping for #{n} sec."
      sleep n
    end
  end
end
