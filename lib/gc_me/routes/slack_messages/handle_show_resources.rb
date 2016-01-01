# frozen_string_literal: true

require 'coach'
require 'yaml'
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
          resource_type, _show, id = params.fetch(:text).split(' ')

          resource = gc_client.show(resource_type, id)
          body     = serialise_resource(resource)

          [200, {}, [body]]
        end

        private

        def serialise_resource(resource)
          yaml = resource.to_h.to_yaml.split("\n")[1..-1].join("\n")

          "```\n#{yaml}\n```"
        end
      end
    end
  end
end
