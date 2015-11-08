require 'coach'
require 'gocardless_pro'
require_relative 'gc_environment_provider'
require_relative 'get_gc_access_token'
require_relative '../gc_client'

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
        pro_client = GoCardlessPro::Client.new(environment: gc_environment,
                                               access_token: gc_access_token)

        provide(gc_client: GCClient.new(pro_client))

        next_middleware.call
      end
    end
  end
end
