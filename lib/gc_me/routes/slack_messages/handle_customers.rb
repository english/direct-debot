# frozen_string_literal: true

require 'coach'
require 'json'
require_relative '../../middleware/get_gc_access_token'
require_relative '../../middleware/build_gc_client'
require_relative '../../refinements/hash_slice'

module GCMe
  module Routes
    module SlackMessages
      # List all GC customers
      class HandleCustomers < Coach::Middleware
        using Refinements::HashSlice

        uses Middleware::GetGCAccessToken, -> (config) { config.slice!(:store) }

        uses Middleware::BuildGCClient,
             -> (config) { config.slice!(:store, :gc_environment) }

        requires :gc_client

        def call
          customers = gc_client.customers

          body = serialise_customers(customers)

          [200, {}, [body]]
        end

        private

        def serialise_customers(customers)
          json = JSON.pretty_generate(customers.map(&:to_h).to_a)

          "```\n#{json}\n```"
        end
      end
    end
  end
end
