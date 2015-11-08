require 'coach'

module GCMe
  module Middleware
    # Exposes `gc_environment` to middlewares downsteam, allowing for injection if
    # required
    class GCEnvironmentProvider < Coach::Middleware
      provides :gc_environment

      def call
        provide(gc_environment: request.env.fetch('injected.gc_environment'))
        next_middleware.call
      end
    end
  end
end
