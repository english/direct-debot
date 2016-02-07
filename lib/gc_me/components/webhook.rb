# frozen_string_literal: true

require_relative 'db'
require_relative 'server'
require_relative '../jobs/webhook_event'

module GCMe
  module Components
    # Wraps up the Webhook library with a minimal interface.
    class Webhook
      def self.depends_on
        { DB => :db_component, Server => :server_component }
      end

      attr_reader :input_queue
      attr_writer :db_component, :server_component

      def initialize(input_queue, slack_bot_api_token)
        @input_queue = input_queue
        @slack_bot_api_token = slack_bot_api_token
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
              @server_component.slack_bot_api_token,
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
