# frozen_string_literal: true

require 'coach'
require_relative '../middleware/json_schema'
require_relative '../middleware/build_gc_client'

module GCMe
  module Routes
    # Handle redirect flow completion
    module AddCustomerSuccess
      # Fetches the redirect flow given in params from the store.
      # Responds with a 422 if the redirect flow is not found.
      class GetRedirectFlow < Coach::Middleware
        provides :redirect_flow

        def call
          store = config.fetch(:store)
          gc_redirect_flow_id = params.fetch(:redirect_flow_id)

          redirect_flow = store.find_redirect_flow(gc_redirect_flow_id)

          if redirect_flow
            provide(redirect_flow: redirect_flow)
            next_middleware.call
          else
            [422, {}, ["redirect_flow #{gc_redirect_flow_id} not found"]]
          end
        end
      end

      # Fetches the GoCardless access token from the store for the given redirect flow's
      # user.
      # TODO: handle case where access token not found.
      class GetGCAccessTokenFromRedirectFlow < Coach::Middleware
        requires :redirect_flow
        provides :gc_access_token

        def call
          store = config.fetch(:store)
          redirect_flow_id = redirect_flow.fetch(:id)

          gc_access_token = store.find_access_token_for_redirect_flow(redirect_flow_id)

          provide(gc_access_token: gc_access_token)
          next_middleware.call
        end
      end

      # Route handler. Gets a redirect flow and completes it.
      class Handler < Coach::Middleware
        SCHEMA = {
          'type' => 'object',
          'required' => %w(redirect_flow_id),
          'additionalProperties': false,
          'properties' => {
            'redirect_flow_id' => { 'type' => 'string' }
          }
        }

        uses Middleware::JSONSchema, schema: SCHEMA
        uses GetRedirectFlow, -> (config) { config.slice(:store) }
        uses GetGCAccessTokenFromRedirectFlow, -> (config) { config.slice(:store) }
        uses Middleware::BuildGCClient, -> (config) { config.slice(:gc_environment) }

        requires :gc_client, :redirect_flow

        def call
          gc_client.complete_redirect_flow(redirect_flow.fetch(:gc_redirect_flow_id))

          [200, {}, ['boom']]
        end
      end
    end
  end
end
