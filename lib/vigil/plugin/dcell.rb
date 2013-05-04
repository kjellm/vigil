require 'dcell'

class Vigil
  module Plugin
    class DCell < Plugman::PluginBase
      include Celluloid
      include Celluloid::Logger

      def self.new
        raise
      end

      def initialize
        raise
        ::DCell.start :id => "vigil", :addr => "tcp://127.0.0.1:1234"
        @node = ::DCell::Node["vigil_web_server"]
        @inbox_service = @node[:inbox]
      end

      def build_started(project)
        info "Build started"
        @inbox_service.notify(project, 'build', 'started')
      end
    
      def task_started(project, task)
        info "Task started: #{task}"
        @inbox_service.notify(project, task, 'started')
      end

      def task_done(project, task)
        info "Task done: #{task}"
        @inbox_service.notify(project, task, 'done')
      end
    end
  end
end

