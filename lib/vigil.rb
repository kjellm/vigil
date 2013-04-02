require 'vigil/task'

require 'plugman'
require 'vigil/config'
require 'vigil/gem_pipeline'
require 'vigil/git'
require 'vigil/os'
require 'vigil/pipeline'
require 'vigil/poll'
require 'vigil/project'
require 'vigil/project_repository'
require 'vigil/revision'
require 'vigil/revision_repository'
require 'vigil/test_pipeline'
require 'vigil/vagrant'
require 'vigil/vmbuilder'

class Vigil
  
  class << self
    attr_accessor :os
    attr_accessor :run_dir
    attr_accessor :plugman
    attr_accessor :logger
  end

  begin
    Vigil.os = Vigil::OS.new
    Vigil.run_dir = File.expand_path('run')
    Vigil.logger = Logger.new($stderr)
    Vigil.plugman = Plugman.new(logger: Vigil.logger)
  end

  def initialize(args = {})
    @config = Config.new(args)
    Vigil.os = args[:os] if args[:os]
    Vigil.run_dir = @config[:run_dir] if @config[:run_dir]
    Vigil.plugman = Plugman.new(logger: Vigil.logger, loader: Plugman::ConfigLoader.new(@config['plugins']))
    @project_repository = ProjectRepository.new(@config)
    @os = Vigil.os
    @loop = args[:loop] || Poll.new(60)
    @log = Vigil.logger
  end
  
  def run
    @os.mkdir_p Vigil.run_dir
    @loop.call do
      @log.debug "LOOP"
      @project_repository.to_a.each do |p|
        p.synchronize
        p.run_pipeline if p.new_revision?
      end
    end
  end

  def project(name)
    @project_repository.find(name)
  end

  def latest_revision(project_name)
    project(project_name).most_recent_revision
  end

end
