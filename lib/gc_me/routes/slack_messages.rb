# frozen_string_literal: true

require 'coach'
require 'hamster'
require_relative '../middleware/build_gc_client'
require_relative '../middleware/get_gc_access_token'
require_relative '../middleware/get_gc_customer'
require_relative '../middleware/get_gc_mandate'
require_relative '../middleware/json_schema'
require_relative '../middleware/parse_payment_message'
require_relative '../middleware/verify_slack_token'
require_relative '../refinements/hash_slice'
require_relative 'slack_messages/handle_add_customer'
require_relative 'slack_messages/handle_authorize'
require_relative 'slack_messages/handle_payment'
require_relative 'slack_messages/handle_list_resources'
require_relative 'slack_messages/handle_show_resources'

module GCMe
  module Routes
    module SlackMessages
      # Handles Slack messages in the format of
      #   /gc-me <amount> from <user>
      # or
      #   /gc-me authorise
      # or
      #   /gc-me add someone@example.com
      class Handler < Coach::Middleware
        # We should never really see this error since the JSON schema will reject
        # unexpected 'text' requests.
        class RouteNotFoundError < StandardError
          def initialize(text)
            super("could not match route with text: #{text}")
          end
        end

        using Refinements::HashSlice

        AUTHORISE_REGEXP       = /^authorise$/
        PAYMENT_REGEXP         = /^(?:((?:£|€)[0-9]+(\.[0-9]+)?) from .+)$/
        ADD_CUSTOMER_REGEXP    = /^add .+@.+\..+$/
        EXPOSED_RESOURCES = Hamster::List['customer_bank_accounts', 'customers',
                                          'events', 'mandates', 'payments', 'payouts',
                                          'refunds', 'subscriptions']
        LIST_RESOURCES_REGEXP  = /^list (#{EXPOSED_RESOURCES.join('|')})$/
        SHOW_RESOURCES_REGEXP  = /^show (#{EXPOSED_RESOURCES.join('|')}) [A-Z0-9]+$/

        TEXT_PATTERN = [
          AUTHORISE_REGEXP, PAYMENT_REGEXP, ADD_CUSTOMER_REGEXP, LIST_RESOURCES_REGEXP,
          SHOW_RESOURCES_REGEXP
        ].map { |re| "(#{re})" }.join('|')

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
        uses Middleware::VerifySlackToken, -> (config) { config.slice!(:slack_token) }

        ROUTE_TABLE = Hamster::Hash.new(
          ADD_CUSTOMER_REGEXP   => [HandleAddCustomer, [:mail_client, :store, :host]],
          AUTHORISE_REGEXP      => [HandleAuthorize, [:oauth_client]],
          PAYMENT_REGEXP        => [HandlePayment, [:store, :gc_environment]],
          LIST_RESOURCES_REGEXP => [HandleListResources, [:store, :gc_environment]],
          SHOW_RESOURCES_REGEXP => [HandleShowResources, [:store, :gc_environment]]
        )

        def call
          text = params.fetch(:text)
          route_klass, config_keys = match_route(text)

          fail RouteNotFoundError, text unless route_klass

          Coach::Handler.
            new(route_klass, config.slice!(*config_keys)).
            call(request.env)
        end

        private

        def match_route(text)
          ROUTE_TABLE.
            select { |key, _| key.match(text) }.
            values.
            first
        end
      end
    end
  end
end
