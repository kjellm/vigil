require 'erb'
require 'reel'

class Vigil
  module Web
    class Server < Reel::Server
      include Celluloid::Logger
    
      def initialize(host = "0.0.0.0", port = 1236)
        info "Web server starting on #{host}:#{port}"
        @vigil = Vigil.new
        @config = Vigil::Config.new
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
        info "URL: #{request.url}"
        case request.url
        when "/"
          return render_index(connection)
        when /\/project\/.*/
          parts = request.url.split('/')
          return render_project(parts[2], connection)
        when /\/(static\/.*)/
          return static(connection, request, $1)
        when /coverage\/([^\/]*)\/?(.*)?/
          if $1 == $2
            return static(connection, request, File.join(@vigil.latest_revision($1).working_dir, 'coverage/index.html'))
          else
            return static(connection, request, File.join(@vigil.latest_revision($1).working_dir, 'coverage', $2))
          end
        end
        info "HERE"
        not_found(connection, request.path)
      end
    
      def static(connection, request, file)
        return not_found(connection, file) unless File.exists?(file)
        info "200 OK: #{request.url}"
        html = File.read(file)
        return connection.respond :ok, html
      end
    
      def not_found(connection, path)
        info "404 Not Found: #{path}"
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
        projects = @config.opts["projects"].keys
        html = ERB.new(File.read("html/list.html.erb")).result(binding)
        connection.respond :ok, html
      end
    
      def render_project(name, connection)
        project = @vigil.project(name)
        data = {
          name: project.name,
          readme: project.readme,
          reports: project.revisions.map {|r| r.report},
        }
        unless project
          info "404 Not Found: FIXME"
          return connection.respond :not_found, "Not found"
        end
        info "200 OK: /project/#{name}"
        html = ERB.new(File.read("html/project.html.erb")).result(binding)
        connection.respond :ok, html
      end
    end

  end
end
