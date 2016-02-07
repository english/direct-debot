# frozen_string_literal: true

require 'hamster'
require 'gocardless_pro'
require 'net/http'
require_relative '../gc_client'
require_relative '../db/store'

module GCMe
  module Jobs
    class WebhookEvent
      def initialize(database, environment, slack_queue, organisation_id, event_id)
        @database = database
        @environment = environment
        @slack_queue = slack_queue
        @organisation_id = organisation_id
        @event_id = event_id
      end

      def perform!
        store   = GCMe::DB::Store.new(@database)
        user    = store.find_user_by_organisation_id(@organisation_id)
        event   = get_latest_event!(@event_id, user, @environment)
        message = make_slack_message(event, user)

        @slack_queue << message
      end

      private

      def get_latest_event!(event_id, user, gc_environment)
        client = GoCardlessPro::Client.new(environment: gc_environment,
                                           access_token: user.fetch(:gc_access_token),
                                           connection_options: { request: { timeout: 1 } })
        gc_client = GCClient.new(client)

        gc_client.show('events', event_id)
      end

      def make_slack_message(event, user)
        Hamster::Hash.new(
          channel: user.fetch(:slack_user_id),
          as_user: 'true',
          text: "#{format_resource(event.resource_type)} #{event.links.payment} #{event.action}"
        )
      end

      def format_resource(string)
        string.capitalize.chomp('s')
      end
    end
  end
end