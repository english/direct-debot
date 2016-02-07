# frozen_string_literal: true

require_relative 'db'
require_relative 'server'
require_relative '../jobs/webhook_event'

module GCMe
  module Components
    # Wraps up the Webhook library with a minimal interface.
    class Webhook
      def self.depends_on
        { DB => :db_component, Server => :server_component, Slack => :slack_component }
      end

      attr_reader :input_queue
      attr_writer :db_component, :server_component, :slack_component

      def initialize(input_queue)
        @input_queue = input_queue
        @running = false
      end

      def start
        return self if @running

        @running = true

        thread = Thread.new do
          while @running
            message = @input_queue.pop

            job = GCMe::Jobs::WebhookEvent.new(
              @db_component.database,
              @server_component.environment,
              @slack_component.input_queue,
              message.fetch(:organisation_id),
              message.fetch(:event_id)
            )

            job.perform!

            sleep(0.1)
          end
        end

        thread.abort_on_exception = true

        self
      end

      def stop
        @running = false

        self
      end
    end
  end
end
