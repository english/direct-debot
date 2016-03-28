# frozen_string_literal: true

require 'rack'
require 'puma'
require 'uri'

module GCMe
  module Components
    module Fakes
      # HTTP server to run in development and pretend to be slack
      class SlackServer
        def initialize(uri)
          @port = URI.parse(uri).port
        end

        def start(logger)
          return if @running

          rack_app = build_rack_app(logger)
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
            server.add_tcp_listener('0.0.0.0', @port)
          end
        end

        def build_rack_app(logger)
          lambda { |env|
            request = Rack::Request.new(env)
            logger.info("Got slack message at #{request.path} with #{request.params}")

            if request.path == '/api/chat.postMessage'
              [200, {}, ['Gotcha']]
            else
              [404, {}, ['Not found']]
            end
          }
        end
      end
    end
  end
end
