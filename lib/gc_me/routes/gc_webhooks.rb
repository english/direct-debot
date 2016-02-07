# frozen_string_literal: true

require 'coach'
# require_relative '../middleware/json_schema'
require_relative '../refinements/hash_dig_strict'

module GCMe
  module Routes
    class GCWebhooks < Coach::Middleware
      using Refinements::HashDigStrict

      def call
        queue = config.fetch(:queue)

        params.fetch('events').each do |event|
          queue << {
            organisation_id: event.dig!('links', 'organisation'),
            event_id: event.fetch('id')
          }
        end

        # Wait for the queue to be drained
        # Remove this once a proper peristent background queue is setup
        sleep 0.1 until queue.empty?

        [204, {}, ['']]
      end
    end
  end
end
