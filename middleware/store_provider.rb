require 'coach'

module Middleware
  # Exposes `Store` to middlewares downsteam, allowing for injection if required
  class StoreProvider < Coach::Middleware
    provides :store

    def call
      provide(store: request.env.fetch('injected.store'))
      next_middleware.call
    end
  end
end
