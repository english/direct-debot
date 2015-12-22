require 'coach'
require 'json'
require_relative '../middleware/json_schema'

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

      def call
        store, oauth_client = config.fetch_values(:store, :oauth_client)
        code, state = params.fetch_values('code', 'state')

        access_token = oauth_client.create_access_token!(code)
        store.create_user!(gc_access_token: access_token, slack_user_id: state)

        [200, {}, ['Gotcha!']]
      end
    end
  end
end
