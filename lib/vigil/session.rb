class Vigil
  class Session
    attr_accessor :revision
    attr_accessor :plugman
    attr_accessor :system

    def initialize(args)
      @revision = args.fetch(:revision)
      @plugman = args.fetch(:plugman)
      @system = args.fetch(:system)
    end

  end
end
