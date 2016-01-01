# frozen_string_literal: true

require 'coach'
require 'yaml'
require_relative '../../middleware/get_gc_access_token'
require_relative '../../middleware/build_gc_client'
require_relative '../../refinements/hash_slice'

module GCMe
  module Routes
    module SlackMessages
      # List all GC resources
      class HandleListResources < Coach::Middleware
        using Refinements::HashSlice

        uses Middleware::GetGCAccessToken, -> (config) { config.slice!(:store) }

        uses Middleware::BuildGCClient,
             -> (config) { config.slice!(:store, :gc_environment) }

        requires :gc_client

        def call
          resource_type = params.fetch(:text).split(' ').first

          resources = gc_client.list(resource_type)
          body      = serialise_resources(resources)

          [200, {}, [body]]
        end

        private

        def serialise_resources(resources)
          yaml = resources.map(&:to_h).to_a.to_yaml.split("\n")[1..-1].join("\n")

          "```\n#{yaml}\n```"
        end
      end
    end
  end
end
