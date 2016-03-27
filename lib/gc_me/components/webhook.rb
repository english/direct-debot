# frozen_string_literal: true

require_relative 'db'
require_relative '../consumer'
require_relative '../jobs/webhook_event'
require_relative '../db/store'

module GCMe
  module Components
    # Wraps up the Webhook library with a minimal interface.
    class Webhook
      attr_reader :input_queue, :gc_webhook_secret

      def initialize(gc_webhook_secret, environment, worker_count: 2)
        @worker_count      = worker_count
        @environment       = environment
        @gc_webhook_secret = gc_webhook_secret
        @input_queue       = nil
      end

      def start(logger, db, slack)
        @input_queue = SizedQueue.new(5)

        @consumers = @worker_count.times.map {
          Consumer.call(@input_queue, logger) { |message|
            perform_job(message, db.database, @environment, slack.input_queue)
          }
        }
      end

      def stop
        @input_queue.close
        @consumers.each(&:join)
      end

      private

      def perform_job(message, database, environment, slack_queue)
        GCMe::Jobs::WebhookEvent.call(
          store: GCMe::DB::Store.new(database),
          environment: environment,
          slack_queue: slack_queue,
          organisation_id: message.fetch(:organisation_id),
          event_id: message.fetch(:event_id)
        )
      end
    end
  end
end
