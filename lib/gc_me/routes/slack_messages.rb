require 'coach'
require_relative '../middleware/router_provider'
require_relative '../middleware/oauth_client_provider'
require_relative '../middleware/json_schema'

module GCMe
  module Routes
    # Handles Slack messages in the format of
    #   /gc-me <amount> from <user>
    # or
    #   /gc-me authorise
    class SlackMessages < Coach::Middleware
      TEXT_PATTERN = '^(authorise)|(?:((?:£|€)[0-9]+(\.[0-9]+)?) from (@?[a-zA-Z]+))$'

      SCHEMA = {
        'type' => 'object',
        'required' => %w(token team_id team_domain channel_id channel_name user_id
                         user_name command text),
        'additionalProperties': false,
        'properties' => {
          'token' => { 'type' => 'string' },
          'team_id' => { 'type' => 'string' },
          'team_domain' => { 'type' => 'string' },
          'channel_id' => { 'type' => 'string' },
          'channel_name' => { 'type' => 'string' },
          'user_id' => { 'type' => 'string' },
          'user_name' => { 'type' => 'string' },
          'command' => { 'type' => 'string' },
          'text' => {
            'type' => 'string',
            'pattern' => TEXT_PATTERN
          }
        }
      }

      uses Middleware::JSONSchema, schema: SCHEMA
      uses Middleware::OAuthClientProvider
      uses Middleware::RouterProvider

      requires :oauth_client
      requires :router

      def call
        # TODO: add `state` parameter
        #       fetch user email from slack to prefill
        #       check if already authorised
        slack_user_id = params.fetch('user_id')

        url = oauth_client.auth_code.authorize_url(redirect_uri: redirect_uri,
                                                   state: slack_user_id,
                                                   scope: 'full_access',
                                                   initial_view: 'login')
        label = 'Click me!'
        payload = "<#{url}|#{label}>"

        [200, {}, [payload]]
      end

      def redirect_uri
        uri = URI.parse(router.url(:gc_callback))
        uri.port = nil

        uri.to_s
      end
    end
  end
end
