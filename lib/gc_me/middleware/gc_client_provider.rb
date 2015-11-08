require 'coach'
require_relative '../middleware/gc_environment_provider'
require_relative '../middleware/get_gc_access_token'

module GCMe
  module Middleware
    # Exposes `gc_client` to middlewares downsteam, allowing for injection if required
    class GCClientProvider < Coach::Middleware
      uses Middleware::GCEnvironmentProvider
      uses Middleware::GetGCAccessToken

      requires :gc_environment
      requires :gc_access_token

      provides :gc_client

      def call
        client = GCClient.new(gc_environment, gc_access_token)

        provide(gc_client: client)

        next_middleware.call
      end
    end
  end
end
