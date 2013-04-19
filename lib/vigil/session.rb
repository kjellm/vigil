class Vigil
  class Session

    attr_accessor :env
    attr_accessor :plugman
    attr_accessor :revision
    attr_accessor :system

    def initialize(args)
      @env      = args.fetch(:env)
      @plugman  = args.fetch(:plugman)
      @revision = args.fetch(:revision)
      @system   = args.fetch(:system)
    end

  end
end
