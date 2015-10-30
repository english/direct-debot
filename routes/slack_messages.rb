require 'coach'
require_relative '../middleware/router_provider'
require_relative '../middleware/oauth_client_provider'

module Routes
  # Handles Slack messages in the format of
  #   /gc-me <amount> from <user>
  # or
  #   /gc-me authorise
  class SlackMessages < Coach::Middleware
    uses Middleware::OauthClientProvider
    uses Middleware::RouterProvider

    requires :oauth_client
    requires :router

    def call
      # TODO: add `state` parameter
      #       fetch user email from slack to prefill
      #       check if already authorised
      url = oauth_client.auth_code.authorize_url(redirect_uri: redirect_uri,
                                                 scope: 'full_access',
                                                 initial_view: 'signup')

      formatted_url = "<#{url}>"

      [200, {}, [formatted_url]]
    end

    def redirect_uri
      uri = URI.parse(router.url(:gc_callback))
      uri.port = nil

      uri.to_s
    end
  end
end
