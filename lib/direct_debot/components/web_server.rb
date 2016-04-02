# frozen_string_literal: true

require_relative '../../direct_debot'
require 'airbrake'
require 'rack'
require 'puma'
require 'uri'

module DirectDebot
  module Components
    # Controls starting and stopping the Rack web server
    class WebServer
      attr_reader :host, :rack_app, :environment

      def initialize(thread_count, port, host, environment, oauth_client)
        @thread_count = thread_count
        @port         = port
        @host         = URI.parse(host)
        @environment  = environment.to_sym
        @oauth_client = oauth_client
      end

      def start(db, mail, webhook, slack)
        return if @running

        router = Application.new(db, mail, webhook, slack, self, @oauth_client)

        @rack_app = ::Rack::Builder.new do
          use ::Airbrake::Rack::Middleware
          run router.rack_app
        end

        @server = build_server(rack_app)
        @server.run
        @running = true
      end

      def stop
        @server.stop(true)
        @running = false
      end

      private

      def build_server(rack_app)
        Puma::Server.new(rack_app).tap do |server|
          server.min_threads = server.max_threads = @thread_count
          server.add_tcp_listener('0.0.0.0', @port)
        end
      end
    end
  end
end
