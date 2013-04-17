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
    Vigil.plugman = Plugman.new(logger: Vigil.logger, loader: Plugman::ConfigLoader.new(@config['plugins']))
    Vigil.plugman.load_plugins
    Vigil.logger = args[:logger] if args[:logger]
    @project_repository = ProjectRepository.new(@config)
    @os = Vigil.os
    @loop = args[:loop] || Poll.new(60)
    @log = Vigil.logger
  end
  
  def run
    #EE.wrap do
    @os.mkdir_p Vigil.run_dir
    @loop.call do
      @log.debug "LOOP"
      @project_repository.to_a.each do |p|
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

end
