require 'ostruct'
require 'singleton'

class Vigil
  class GemPipeline

    class Environment
      include Singleton
    
      attr_reader :system
    
      def initialize()
        @system = System.new
      end
    
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
    
      def initialize(env=Environment.instance)
        @env = env
      end
    
      def call
        result = @env.system.run_command(command)
        return OpenStruct.new(status: result.status, command: command, result: result)
      end
    
      private
    
      def command; raise "Abstract method called"; end
    
    end
    
    class InstallGemsTask < Task
    
      private
    
      def command
        %w(bundle install)
      end
    
    end
    
    class TestTask < Task
    
      private
    
      def command
        %w(bundle exec rake)
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
  
    def initialize(*args)
    end

    def run
      log = []
      log << res = InstallGemsTask.new.call
      log << res = TestTask.new.call if res.status
  
      return Report.new(res.status, log)
    end
  
  end
end
