# frozen_string_literal: true

require_relative '../../gc_me'
require 'airbrake'
require 'rack'
require 'puma'
require 'uri'

module GCMe
  module Components
    # Controls starting and stopping the Rack web server
    class WebServer
      attr_reader :host, :environment, :slack_token, :rack_app

      def initialize(thread_count, port, host, environment, slack_token)
        @thread_count = thread_count
        @port         = port
        @host         = URI.parse(host)
        @environment  = environment.to_sym
        @slack_token  = slack_token
      end

      def start(db, oauth, mail, webhook)
        return if @running

        router = GCMe::Application.new(db, oauth, mail, webhook, self)

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
