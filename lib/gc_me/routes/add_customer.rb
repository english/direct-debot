require 'coach'
require_relative '../middleware/json_schema'
require_relative '../middleware/get_gc_access_token'
require_relative '../middleware/gc_client_provider'

module GCMe
  module Routes
    # Redirects a potential customer to a new GC redirect flow
    class AddCustomer < Coach::Middleware
      SCHEMA = {
        'type' => 'object',
        'required' => %w(user_id),
        'additionalProperties': false,
        'properties' => {
          'user_id' => { 'type' => 'string' }
        }
      }

      uses Middleware::JSONSchema, schema: SCHEMA
      # TODO: Configure response for when user not found
      uses Middleware::GetGCAccessToken, -> (config) { config.slice(:store) }
      uses Middleware::GCClientProvider, -> (config) { config.slice(:gc_environment) }

      requires :gc_client

      def call
        success_url = config.fetch(:success_url)

        redirect_flow = gc_client.create_redirect_flow(success_url)

        [302, { 'Location' => redirect_flow.redirect_url }, ['']]
      end
    end
  end
end
