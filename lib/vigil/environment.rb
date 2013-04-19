class Vigil
  class Environment
  
    attr_reader :config
    attr_reader :log
    attr_reader :system

    def initialize(args)
      @config  = args.fetch(:config)
      @log     = args.fetch(:logger)
      @plugman = args.fetch(:plugman)
      @system  = args.fetch(:system)
    end
  
  end
end
