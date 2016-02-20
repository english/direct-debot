# frozen_string_literal: true

require_relative 'db'
require_relative 'server'
require_relative '../jobs/webhook_event'

module GCMe
  module Components
    # Wraps up the Webhook library with a minimal interface.
    class Webhook
      def self.depends_on
        [Logger, DB, Server, Slack]
      end

      attr_reader :input_queue, :gc_webhook_secret

      def initialize(input_queue, gc_webhook_secret, worker_count: 2)
        @input_queue = input_queue
        @worker_count = worker_count
        @gc_webhook_secret = gc_webhook_secret
        @running = false
      end

      def start(logger, db, server, slack)
        @logger = logger
        @db = db
        @server = server
        @slack = slack

        return self if @running

        @running = true

        threads = @worker_count.times.map do
          Thread.new { perform_job(@input_queue.pop) while @running }
        end

        threads.each { |t| t.abort_on_exception = true }
      end

      def stop
        @running = false
      end

      private

      def perform_job(message)
        @logger.logger.info("about to process webhook: #{message}")

        job = GCMe::Jobs::WebhookEvent.new(
          @db.database,
          @server.environment,
          @slack.input_queue,
          message.fetch(:organisation_id),
          message.fetch(:event_id)
        )

        job.perform!
      end
    end
  end
end
