require 'plugman'
#require 'pry-exception_explorer'

Dir[File.join(File.dirname(__FILE__), 'vigil/**/*.rb')].each do |file| 
  dir = File.dirname(file)[File.dirname(__FILE__).length+1..-1]
  file = File.join(dir, File.basename(file, File.extname(file)))
  next if file =~ /plugin/
  require_relative file
end

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
    Vigil.logger = args[:logger] if args[:logger]
    initialize_plugman
    @env = Environment.new(logger: Vigil.logger, config: @config, plugman: Vigil.plugman, system: System.new)
    @project_repository = ProjectRepository.new(@env)
    @os = Vigil.os
    @loop = args[:loop] || Poll.new(60)
  end

  def start
    #EE.wrap do
    @os.mkdir_p Vigil.run_dir
    @loop.call do
      @env.log.info "Polling projects"
      @project_repository.each do |p|
        p.synchronize
        p.run_pipeline if p.new_revision?
      end
    end
    #end
  end

  def project(name)
    @project_repository.find(name)
  end

  def latest_revision(project_name)
    project(project_name).most_recent_revision
  end

  private

  def initialize_plugman
    Vigil.plugman = Plugman.new(logger: Vigil.logger, loader: Plugman::ConfigLoader.new(@config['plugins']))
    Vigil.plugman.load_plugins
  end

end
