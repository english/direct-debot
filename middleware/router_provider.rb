require 'coach'

module Middleware
  # Exposes `router` to middlewares downsteam, allowing for injection if required
  class RouterProvider < Coach::Middleware
    provides :router

    def call
      provide(router: request.env.fetch('injected.router'))
      next_middleware.call
    end
  end
end
