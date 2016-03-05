# frozen_string_literal: true

require 'hamster'
require 'net/http'
require_relative '../gc_client'
require_relative '../db/store'

module GCMe
  module Jobs
    # Processes a webhook event by fetching the latest event and putting an appropriate
    # message on the slack queue
    class WebhookEvent
      def self.call(store:, environment:, slack_queue:, organisation_id:, event_id:)
        user    = store.find_user_by_organisation_id(organisation_id)
        event   = get_latest_event!(event_id, user, environment)
        message = make_slack_message(event, user)

        slack_queue << message
      end

      def self.get_latest_event!(event_id, user, gc_environment)
        client = GCClient.make(environment: gc_environment,
                               access_token: user.fetch(:gc_access_token))

        client.show('events', event_id)
      end
      private_class_method :get_latest_event!

      def self.make_slack_message(event, user)
        text = [
          event.resource_type.capitalize.chomp('s'),
          event.links.payment,
          event.action
        ].join(' ')

        Hamster::Hash.new(
          channel: user.fetch(:slack_user_id),
          as_user: 'true',
          text: text
        )
      end
      private_class_method :make_slack_message
    end
  end
end
