# frozen_string_literal: true

require 'coach'
require_relative '../middleware/json_schema'
require_relative '../middleware/get_gc_access_token'
require_relative '../middleware/build_gc_client'
require_relative '../refinements/hash_slice'

module DirectDebot
  module Routes
    # Redirects a potential customer to a new GC redirect flow
    class AddCustomer < Coach::Middleware
      using Refinements::HashSlice

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
      uses Middleware::GetGCAccessToken, -> (config) { config.slice!(:store) }
      uses Middleware::BuildGCClient, -> (config) { config.slice!(:gc_environment) }

      requires :gc_client

      def call
        slack_user_id = params.fetch(:user_id)
        success_url, store = config.fetch_values(:success_url, :store)

        redirect_flow = gc_client.create_redirect_flow(success_url)
        store.create_redirect_flow!(slack_user_id, redirect_flow.id)

        [302, { 'Location' => redirect_flow.redirect_url }, ['']]
      end
    end
  end
end
