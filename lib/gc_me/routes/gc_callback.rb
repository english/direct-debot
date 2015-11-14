require 'coach'
require 'json'
require_relative '../middleware/json_schema'
require_relative '../middleware/oauth_client_provider'

module GCMe
  module Routes
    # GET https://localhost/callback HTTP/1.1
    #   code=6NJiqXzT7HcgEGsAZXUmaBfB&
    #   state=q8wEr9yMohTP
    class GCCallback < Coach::Middleware
      SCHEMA = {
        'type' => 'object',
        'required' => %w(code state),
        'additionalProperties': false,
        'properties' => {
          'code' => { 'type' => 'string' },
          'state' => { 'type' => 'string' }
        }
      }

      uses Middleware::JSONSchema, schema: SCHEMA
      uses Middleware::OAuthClientProvider

      requires :oauth_client

      def call
        store = config.fetch(:store)
        code  = params.fetch('code')
        state = params.fetch('state')

        access_token = oauth_client.create_access_token!(code)
        store.create_slack_user!(gc_access_token: access_token, slack_user_id: state)

        [200, {}, ['Gotcha!']]
      end
    end
  end
end
