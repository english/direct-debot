# frozen_string_literal: true

require_relative 'db'
require_relative 'server'
require_relative '../jobs/webhook_event'

module GCMe
  module Components
    # Wraps up the Webhook library with a minimal interface.
    class Webhook
      attr_reader :input_queue, :gc_webhook_secret

      def initialize(gc_webhook_secret, worker_count: 2)
        @worker_count      = worker_count
        @gc_webhook_secret = gc_webhook_secret
        @input_queue       = nil
      end

      def start(logger, db, server, slack)
        @logger      = logger
        @db          = db
        @server      = server
        @slack       = slack
        @input_queue = SizedQueue.new(5)

        start_workers
      end

      def stop
        @input_queue.close
      end

      private

      def start_workers
        threads = @worker_count.times.map {
          Thread.new do
            while job = @input_queue.deq
              perform_job(job)
            end
          end
        }

        threads.each { |t| t.abort_on_exception = true }
      end

      def perform_job(message)
        @logger.logger.info("about to process webhook: #{message}")

        store = GCMe::DB::Store.new(@db.database)

        GCMe::Jobs::WebhookEvent.call(
          store: store,
          environment: @server.environment,
          slack_queue: @slack.input_queue,
          organisation_id: message.fetch(:organisation_id),
          event_id: message.fetch(:event_id)
        )
      end
    end
  end
end
