# frozen_string_literal: true

require_relative 'db'
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
        @logger      = logger
        @db          = db
        @slack       = slack
        @input_queue = SizedQueue.new(5)

        start_workers
      end

      def stop
        @input_queue.close
      end

      private

      def start_workers
        @worker_count.times.each do
          thread = Thread.new do
            while job = @input_queue.deq
              perform_job(job)
            end
          end

          thread.abort_on_exception = true
        end
      end

      def perform_job(message)
        @logger.logger.info("about to process webhook: #{message}")

        GCMe::Jobs::WebhookEvent.call(
          store: GCMe::DB::Store.new(@db.database),
          environment: @environment,
          slack_queue: @slack.input_queue,
          organisation_id: message.fetch(:organisation_id),
          event_id: message.fetch(:event_id)
        )
      end
    end
  end
end
