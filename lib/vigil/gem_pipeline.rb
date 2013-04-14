require 'vigil/pipeline'
require 'vigil/task'

class Vigil
  class GemPipeline < Pipeline

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

    def tasks
      [ InstallGemsTask.new(@session), TestTask.new(@session) ]
    end
  
  end
end
