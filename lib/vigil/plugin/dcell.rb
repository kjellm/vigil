require 'dcell'

class Vigil
  module Plugin
    class DCell
      include Celluloid
      include Celluloid::Logger

      def initialize
        ::DCell.start :id => "vigil", :addr => "tcp://127.0.0.1:1234"
        @node = ::DCell::Node["vigil_web_server"]
        @inbox_service = @node[:inbox]
      end

      def build_started
        info "Build started"
        @inbox_service.notify('build_started')
      end
    
      def task_started(task)
        info "Task started: #{task}"
        #@inbox_service.notify(task)
      end

      def task_done(report)
        info "Task done: #{report}"
        @inbox_service.notify(report)
      end
    end
  end
end

