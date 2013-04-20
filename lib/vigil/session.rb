class Vigil
  class Session

    attr_accessor :env
    attr_accessor :revision

    def initialize(args)
      @env      = args.fetch(:env)
      @revision = args.fetch(:revision)
    end

    def notify(*args)
      @env.notify(*args)
    end

    def run_command(command)
      @env.system.run_command(command)
    end

  end
end
