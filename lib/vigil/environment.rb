class Vigil
  class Environment
  
    attr_reader :config
    attr_reader :logger
    attr_reader :plugman
    attr_reader :system

    def initialize(args)
      @config  = args.fetch(:config)
      @logger  = args.fetch(:logger)
      @plugman = args.fetch(:plugman)
      @system  = args.fetch(:system)
    end
  
  end
end
