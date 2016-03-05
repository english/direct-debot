# frozen_string_literal: true

require 'coach'
require_relative 'get_gc_access_token'
require_relative '../gc_client'

module GCMe
  module Middleware
    # Exposes `gc_client` to middlewares downsteam, allowing for injection if required
    class BuildGCClient < Coach::Middleware
      requires :gc_access_token
      provides :gc_client

      def call
        client = GCClient.make(environment: config.fetch(:gc_environment),
                               access_token: gc_access_token)

        provide(gc_client: client)

        next_middleware.call
      end
    end
  end
end
