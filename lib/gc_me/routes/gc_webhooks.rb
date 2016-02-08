# frozen_string_literal: true

require 'coach'
require 'openssl'
# require_relative '../middleware/json_schema'
require_relative '../refinements/hash_dig_strict'

module GCMe
  module Routes
    # Handle GC webhooks by:
    #  1. checking the signature of the webhook
    #  2. if the signature is good, enqueues a job to process it
    class GCWebhooks < Coach::Middleware
      using Refinements::HashDigStrict

      def call
        queue, webhook_secret = config.fetch_values(:queue, :gc_webhook_secret)

        return [498, {}, ['']] unless signature_match?(request, webhook_secret)

        puts '#' * 30
        puts params
        puts '#' * 30
        params.fetch('events').each do |event|
          queue << {
            organisation_id: event.dig!('links', 'organisation'),
            event_id: event.fetch('id')
          }
        end

        # Wait for the queue to be drained
        # Remove this once a proper peristent background queue is setup
        sleep 0.01 until queue.empty?

        [204, {}, ['']]
      end

      private

      def signature_match?(request, webhook_secret)
        request_signature = request.headers['Webhook-Signature']
        body = request.body.read

        digest = OpenSSL::Digest.new('sha256')
        calculated_signature = OpenSSL::HMAC.hexdigest(digest, webhook_secret, body)
        request.body.rewind

        calculated_signature == request_signature
      end
    end
  end
end
