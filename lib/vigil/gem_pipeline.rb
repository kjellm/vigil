require 'ostruct'
require 'singleton'

class Vigil
  class GemPipeline

    class Environment
      include Singleton
    
      attr_reader :system
      attr_reader :plugman

      def initialize
        @system = System.new
        @plugman = Vigil.plugman
      end
    
    end

    class Session
      include Singleton
    
      attr_accessor :revision
    end
    
    class CommandResult
    
      attr_reader :status
      attr_reader :output
      attr_reader :process_status
    
      def initialize(status, output, process_status)
        @status = status
        @output = output
        @process_status = process_status
      end
    
    end
    
    class System
    
      def run_command(command)
        output = ''
        IO.popen([*command, :err=>[:child, :out]]) do |io|
          output = io.read
        end
        return CommandResult.new($?.exitstatus == 0, output, $?.clone)
      end
    
    end
    
    class Task
    
      def initialize(env=Environment.instance, session = Session.instance)
        @env = env
        @session = session
      end
    
      def call
        task_started
        log = []
        res = Class.new {def self.status; true; end}
        commands.each do |cmd|
          if res.status
            res = @env.system.run_command(cmd)
            log << OpenStruct.new(command: cmd, result: res)
          end
        end
        task_done
        return OpenStruct.new(name: name, status: res.status, log: log)
      end
    
      private
    
      def commands; raise "Abstract method called"; end
      def name; raise "Abstract method called"; end
    
      def task_started
        notify(:task_started, name)
      end

      def task_done
        notify(:task_done, name)
      end

      def notify(msg, *args)
        @env.plugman.notify(msg, @session.revision.project_name, *args)
      end
    end

    class InstallGemsTask < Task
    
      private
    
      def name
        'Bundler'
      end

      def commands
        [%w(bundle install)]
      end
    
    end
    
    class TestTask < Task
    
      private
    
      def name
        'Tests'
      end

      def commands
        [%w(bundle exec rake)]
      end
    
    end
    
    class Report
    
      def initialize(status, log)
        @status = status
        @log = log
      end
    
      def to_s
        "Status: #{@status ? 'success' : 'failed'}\n" << @log.map {|l| "$ #{l.command.join(' ')}\n\t" << l.result.output.split("\n").join("\n\t") }.join("\n")
      end
    
    end
  
    def initialize(revision)
      Session.instance.revision = revision
    end

    def run
      log = []
      log << res = InstallGemsTask.new.call
      log << res = TestTask.new.call if res.status
  
      return Report.new(res.status, log)
    end
  
  end
end
