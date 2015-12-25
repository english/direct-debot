# frozen_string_literal: true

require 'coach'
require_relative '../middleware/build_gc_client'
require_relative '../middleware/get_gc_access_token'
require_relative '../middleware/get_gc_customer'
require_relative '../middleware/get_gc_mandate'
require_relative '../middleware/json_schema'
require_relative '../middleware/parse_payment_message'
require_relative '../middleware/verify_slack_token'
require_relative 'slack_messages/handle_add_customer'
require_relative 'slack_messages/handle_authorize'
require_relative 'slack_messages/handle_payment'

module GCMe
  # Middlewares and route handler that process 'authorise' and 'payment' messages
  module Routes
    module SlackMessages
      # Handles Slack messages in the format of
      #   /gc-me <amount> from <user>
      # or
      #   /gc-me authorise
      # or
      #   /gc-me add someone@example.com
      class Handler < Coach::Middleware
        TEXT_PATTERN = '^' \
                         '(authorise)' \
                       '|' \
                         '(?:((?:£|€)[0-9]+(\.[0-9]+)?) from .+)' \
                       '|' \
                       'add .+@.+\..+' \
                       '$'

        SCHEMA = {
          'type'     => 'object',
          'required' => %w(token team_id team_domain channel_id channel_name user_id
                           user_name command text),
          'additionalProperties': false,
          'properties' => {
            'token'        => { 'type' => 'string' },
            'team_id'      => { 'type' => 'string' },
            'team_domain'  => { 'type' => 'string' },
            'channel_id'   => { 'type' => 'string' },
            'channel_name' => { 'type' => 'string' },
            'user_id'      => { 'type' => 'string' },
            'user_name'    => { 'type' => 'string' },
            'command'      => { 'type' => 'string' },
            'text'         => { 'type' => 'string', 'pattern' => TEXT_PATTERN }
          }
        }

        uses Middleware::JSONSchema, schema: SCHEMA
        uses Middleware::VerifySlackToken, -> (config) { config.slice(:slack_token) }
        uses HandleAuthorize, -> (config) { config.slice(:oauth_client) }
        uses HandleAddCustomer, -> (config) { config.slice(:mail_client, :store, :host) }
        uses HandlePayment, -> (config) { config.slice(:store, :gc_environment) }
      end
    end
  end
end
