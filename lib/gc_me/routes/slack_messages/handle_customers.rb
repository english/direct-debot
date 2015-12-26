# frozen_string_literal: true

require 'coach'
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
          emails = customers.map(&:email)

          [200, {}, [emails.join("\n")]]
        end
      end
    end
  end
end
