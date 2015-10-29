require 'coach'

module Middleware
  # Exposes `oauth_client` to middlewares downsteam, allowing for injection if required
  class OauthClientProvider < Coach::Middleware
    provides :oauth_client

    def call
      provide(oauth_client: request.env.fetch('injected.oauth_client'))
      next_middleware.call
    end
  end
end
