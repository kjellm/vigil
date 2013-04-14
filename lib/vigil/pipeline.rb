class Vigil
  class Pipeline

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
          
    def initialize(session, args={})
      @session = session
      @vmbuilder = args[:vmbuilder] || VMBuilder.new(@session)
      @git = Git.new
      @vagrant = args[:vagrant] || Vagrant.new
    end
    
    def run
      notify(:build_started)
      @vmbuilder.run
      StartVMTask.new(@session, vagrant: @vagrant).call
      TestTask.new(@session, vagrant: @vagrant).call
    end
  
    def notify(msg, *args)
      @session.plugman.notify(msg, @session.revision.project_name, *args)
    end

  end
end
