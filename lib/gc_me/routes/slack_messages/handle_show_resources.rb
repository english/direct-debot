# frozen_string_literal: true

require 'coach'
require 'json'
require_relative '../../middleware/get_gc_access_token'
require_relative '../../middleware/build_gc_client'
require_relative '../../refinements/hash_slice'

module GCMe
  module Routes
    module SlackMessages
      # Show all GC resources
      class HandleShowResources < Coach::Middleware
        using Refinements::HashSlice

        uses Middleware::GetGCAccessToken, -> (config) { config.slice!(:store) }

        uses Middleware::BuildGCClient,
             -> (config) { config.slice!(:store, :gc_environment) }

        requires :gc_client

        def call
          _, resource_type, id = params.fetch(:text).split(' ')

          resource = gc_client.show(resource_type, id)
          body     = serialise_resource(resource)

          [200, {}, [body]]
        end

        private

        def serialise_resource(resource)
          json = JSON.pretty_generate(resource.to_h)

          "```\n#{json}\n```"
        end
      end
    end
  end
end
