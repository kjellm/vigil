class Vigil
  module Web
    class WebsocketHandler
      include Celluloid
      include Celluloid::Notifications
      include Celluloid::Logger
      
      def initialize(websocket)
        @socket = websocket
        subscribe('message_received', :message_received)
      end

      def message_received(topic, project, task, status)
        info "#{self}: #{topic}, #{project}, #{task}, #{status}"
        @socket << "#{project}.#{task}.#{status}"
      rescue Reel::SocketError
        info "Client disconnected"
        terminate
      end
    end

  end
end
