require 'vigil/os'
require 'vigil/pipeline'
require 'vigil/project'
require 'vigil/revision'
require 'vigil/revision_repository'
require 'vigil/vagrant'
require 'vigil/vmbuilder'

class Vigil
  
  class << self
    attr :os, true
  end

  def initialize(args)
    @x = args[:os] || Vigil::OS.new
    Vigil.os = @x
    projects = args[:projects] || []
    @run_dir = File.expand_path 'run'
    @projects = projects.map {|p| Project.new(name: p[:name], os: @x, run_dir: @run_dir, git_url: p[:git][:url], branch: p[:git][:branch]) }

    @x.mkdir_p @run_dir

  end
  
  def run
    loop do
      _not_more_often_than_every(60) do
        puts "### Vigil loop"
        @projects.each do |p|
          puts "## #{p.inspect}"
          p.run_pipeline
        end
      end
    end
  end

  def _not_more_often_than_every(n_seconds)
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
