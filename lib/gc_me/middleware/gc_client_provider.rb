require 'coach'

module GCMe
  module Middleware
    # Exposes `gc_client` to middlewares downsteam, allowing for injection if required
    class GCClientProvider < Coach::Middleware
      provides :gc_client

      def call
        provide(gc_client: request.env.fetch('injected.gc_client'))
        next_middleware.call
      end
    end
  end
end
