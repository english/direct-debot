require 'coach'
require_relative '../middleware/json_schema'
require_relative '../middleware/get_gc_access_token'
require_relative '../middleware/build_gc_client'

module GCMe
  module Routes
    # Handle redirect flow completion
    class AddCustomerSuccess < Coach::Middleware
      SCHEMA = {
        'type' => 'object',
        'required' => %w(redirect_flow_id),
        'additionalProperties': false,
        'properties' => {
          'redirect_flow_id' => { 'type' => 'string' }
        }
      }

      uses Middleware::JSONSchema, schema: SCHEMA
      # uses Middleware::GetGCAccessToken, -> (config) { config.slice(:store) }
      # uses Middleware::BuildGCClient, -> (config) { config.slice(:gc_environment) }

      # requires :gc_client

      def call
        redirect_flow_id = params.fetch(:redirect_flow_id)
        gc_environment, store = config.fetch_values(:gc_environment, :store)

        access_token = store.find_access_token_for_redirect_flow(redirect_flow_id)

        pro_client = GoCardlessPro::Client.new(environment: gc_environment,
                                               access_token: access_token)
        gc_client = GCClient.new(pro_client)

        gc_client.complete_redirect_flow(redirect_flow_id)

        [200, {}, ['boom']]
      end
    end
  end
end
