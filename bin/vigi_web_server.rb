#! /usr/bin/env ruby

require 'reel'
require 'dcell'

DCell.start :id => "vigil_web_server", :addr => "tcp://127.0.0.1:1235"

class Inbox
  include Celluloid
  include Celluloid::Notifications
  include Celluloid::Logger

  def notify(msg)
    info "Inbox: #{msg}"
    publish 'message_received', msg
  end
end

class WebsocketHandler
  include Celluloid
  include Celluloid::Notifications
  include Celluloid::Logger

  def initialize(websocket)
    @socket = websocket
    subscribe('message_received', :message_received)
  end

  def message_received(topic, message)
    info "#{self}: #{topic}, #{message}"
    @socket << message
  rescue Reel::SocketError
    info "Time client disconnected"
    terminate
  end
end

class WebServer < Reel::Server
  include Celluloid::Logger

  def initialize(host = "127.0.0.1", port = 1236)
    info "Web server starting on #{host}:#{port}"
    super(host, port, &method(:on_connection))
  end

  def on_connection(connection)
    while request = connection.request
      case request
      when Reel::Request
        route_request connection, request
      when Reel::WebSocket
        info "Received a WebSocket connection"
        route_websocket request
      end
    end
  end

  def route_request(connection, request)
    if request.url == "/"
      return render_index(connection)
    end

    info "404 Not Found: #{request.path}"
    connection.respond :not_found, "Not found"
  end

  def route_websocket(socket)
    if socket.url == "/messages"
      WebsocketHandler.new(socket)
    else
      info "Received invalid WebSocket request for: #{socket.url}"
      socket.close
    end
  end

  def render_index(connection)
    info "200 OK: /"
    html = File.read("html/index.html")
    connection.respond :ok, html
  end
end

Inbox.supervise_as :inbox
WebServer.supervise_as :reel
sleep
