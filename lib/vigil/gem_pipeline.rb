require 'ostruct'

require 'vigil/task'

class Vigil
  class GemPipeline

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
  
    def initialize(session)
      @session = session
    end

    def run
      log = []
      log << res = InstallGemsTask.new(@session).call
      log << res = TestTask.new(@session).call if res.status
  
      return Report.new(res.status, log)
    end
  
  end
end
