require 'vigil/task'

require 'plugman'
require 'vigil/config'
require 'vigil/gem_pipeline'
require 'vigil/git'
require 'vigil/os'
require 'vigil/pipeline'
require 'vigil/project'
require 'vigil/project_repository'
require 'vigil/revision'
require 'vigil/revision_repository'
require 'vigil/test_pipeline'
require 'vigil/vagrant'
require 'vigil/vmbuilder'

class Vigil
  
  class << self
    attr :os, true
    attr :run_dir, true
    attr :plugman, true
  end

  def initialize(args)
    @config = Config.new(args)
    @x = args[:os] || Vigil::OS.new
    Vigil.os = @x
    Vigil.run_dir = File.expand_path 'run'
    Vigil.plugman = Plugman.new(logger: Logger.new($stderr), loader: Plugman::ConfigLoader.new(args['plugins']))
    p args
    @project_repository = ProjectRepository.new(@config)
  end
  
  def run
    @x.mkdir_p Vigil.run_dir
    loop do
      _less_often_than_every(60) do
        puts "### Vigil loop"
        @project_repository.to_a.each do |p|
          puts "## #{p.inspect}"
          p.synchronize
          p.run_pipeline if p.new_revision?
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
