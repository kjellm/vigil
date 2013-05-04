require 'celluloid'

class Vigil
  module Web
    class Inbox
      include Celluloid
      include Celluloid::Notifications
      include Celluloid::Logger
    
      def notify(project, task, status)
        info "Inbox: '#{project}' '#{task}' '#{status}'"
        publish 'message_received', project, task, status
      end
    end

  end
end
