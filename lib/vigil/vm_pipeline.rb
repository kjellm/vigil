require 'vigil/pipeline'
require 'vigil/task'

class Vigil
  class VMPipeline < Pipeline

    class TestTask < Task
    
      private

      def post_initialize(args)
        @vagrant = args.fetch(:vagrant)
      end

      def name
        'Tests'
      end

      def commands
        [@vagrant.ssh('cd /vagrant; bundle exec rake')]
      end
    
    end

    def run
      @vmbuilder.run
      super
    end

    private
          
    def post_initialize(args)
      @git = args[:git] || Git.new
      @vmbuilder = args[:vmbuilder] || VMBuilder.new(@session)
      @vagrant = args[:vagrant] || Vagrant.new
    end
    
    def tasks
      [ StartVMTask.new(@session, vagrant: @vagrant), TestTask.new(@session, vagrant: @vagrant) ]
    end
  
  end
end
