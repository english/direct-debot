# frozen_string_literal: true

require 'hamster'
require 'gocardless_pro'
require 'net/http'
require_relative 'db'
require_relative '../gc_client'
require_relative '../db/store'

# trap(:INFO) {
#   Thread.list.each do |t|
#     puts "#" * 90
#     p t
#     puts t.backtrace
#     puts "#" * 90
#   end
# }

module GCMe
  module Components
    # Wraps up the Webhook library with a minimal interface.
    class Webhook
      def self.depends_on
        { DB => :db_component , Server => :server_component }
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
            job = EventJob.new(@db_component.database, @server_component, message)
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

    class EventJob
      def initialize(database, server_component, organisation_id:, event_id:)
        @database = database
        @server_component = server_component
        @organisation_id = organisation_id
        @event_id = event_id
      end

      def perform!
        store   = GCMe::DB::Store.new(@database)
        user    = store.find_user_by_organisation_id(@organisation_id)
        event   = get_latest_event!(@event_id, user)
        message = make_slack_message(event, user, @server_component.slack_bot_api_token)

        send_slack_message!(message)
      end

      private

      def get_latest_event!(event_id, user)
        gc_environment = @server_component.environment
        client = GoCardlessPro::Client.new(environment: gc_environment,
                                           access_token: user.fetch(:gc_access_token),
                                           connection_options: { request: { timeout: 1 } })
        gc_client = GCClient.new(client)

        gc_client.show('events', event_id)
      end

      def make_slack_message(event, user, slack_bot_api_token)
        Hamster::Hash.new(
          channel: user.fetch(:slack_user_id),
          token: slack_bot_api_token,
          as_user: 'true',
          text: "#{format_resource(event.resource_type)} #{event.links.payment} #{event.action}"
        )
      end

      def send_slack_message!(message)
        Net::HTTP.post_form(URI('https://slack.com/api/chat.postMessage'), message.to_h)
      end

      def format_resource(string)
        string.capitalize.chomp('s')
      end
    end
  end
end
