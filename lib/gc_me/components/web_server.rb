# frozen_string_literal: true

require_relative '../../gc_me'
require 'airbrake'
require 'rack'
require 'puma'

module GCMe
  module Components
    # Controls starting and stopping the Rack web server
    class WebServer
      def initialize(thread_count, port)
        @thread_count = thread_count
        @port         = port
      end

      def start(db, server_configuration, oauth, mail, webhook)
        return if @running

        app = GCMe::Application.new(db, server_configuration, oauth, mail, webhook)

        rack_app = ::Rack::Builder.new do
          use ::Airbrake::Rack::Middleware
          run app.rack_app
        end

        @server = Puma::Server.new(rack_app)
        configure(@server)
        @server.run
        @running = true
      end

      def stop
        @server.stop(true)
        @running = false
      end

      private

      def configure(server)
        server.min_threads = server.max_threads = @thread_count
        server.add_tcp_listener('0.0.0.0', @port)
      end
    end
  end
end
