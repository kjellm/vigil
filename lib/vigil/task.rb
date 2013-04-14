require 'ostruct'

class Vigil
  class Task
    
    def initialize(session, args={})
      @session = session
      post_initialize(args)
    end
    
    def call
      task_started
      log = []
      res = Class.new {def self.status; true; end}
      commands.each do |cmd|
        if res.status
          res = @session.system.run_command(cmd)
          log << OpenStruct.new(command: cmd, result: res)
        end
      end
      task_done
      return OpenStruct.new(name: name, status: res.status, log: log)
    end
    
    private
    
    def post_initialize(args); end
    
    def commands; raise "Abstract method called"; end
    def name; raise "Abstract method called"; end
    
    def task_started
      notify(:task_started, name)
    end

    def task_done
      notify(:task_done, name)
    end

    def notify(msg, *args)
      @session.plugman.notify(msg, @session.revision.project_name, *args)
    end

  end
end
