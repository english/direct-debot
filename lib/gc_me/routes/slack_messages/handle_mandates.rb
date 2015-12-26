# frozen_string_literal: true

require 'coach'
require 'json'
require_relative '../../middleware/get_gc_access_token'
require_relative '../../middleware/build_gc_client'
require_relative '../../refinements/hash_slice'

module GCMe
  module Routes
    module SlackMessages
      # List all GC mandates
      class HandleMandates < Coach::Middleware
        using Refinements::HashSlice

        uses Middleware::GetGCAccessToken, -> (config) { config.slice!(:store) }

        uses Middleware::BuildGCClient,
             -> (config) { config.slice!(:store, :gc_environment) }

        requires :gc_client

        def call
          mandates = gc_client.mandates

          body = format_mandates(mandates)

          [200, { 'content-type' => 'application/json' }, [body]]
        end

        private

        def format_mandates(mandates)
          {
            text: 'Your mandates',
            attachments: mandates.map { |mandate| format_mandate(mandate) }.to_a
          }.to_json
        end

        def format_mandate(mandate)
          fields = mandate.to_h.
            map { |key, val| { title: key, value: val.to_s, short: true } }

          { fields: fields }
        end
      end
    end
  end
end
