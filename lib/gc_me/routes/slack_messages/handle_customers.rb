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

          body = format_customers(customers)

          [200, {}, [body]]
        end

        private

        def format_customers(customers)
          {
            attachments: customers.map { |customer| format_customer(customer) }.to_a
          }.to_json
        end

        def format_customer(customer)
          {
            text: "#{customer.given_name} #{customer.family_name}",
            fields: [
              { title: 'ID', value: customer.id, short: true },
              { title: 'Email', value: customer.email, short: true }
            ]
          }
        end
      end
    end
  end
end
