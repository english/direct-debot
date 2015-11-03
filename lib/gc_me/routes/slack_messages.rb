require 'coach'
require_relative '../middleware/oauth_client_provider'
require_relative '../middleware/store_provider'
require_relative '../middleware/gc_client_provider'
require_relative '../middleware/json_schema'

module GCMe
  module Routes
    # Handles Slack messages in the format of
    #   /gc-me <amount> from <user>
    # or
    #   /gc-me authorise
    class SlackMessages < Coach::Middleware
      TEXT_PATTERN = '^(authorise)|(?:((?:£|€)[0-9]+(\.[0-9]+)?) from .+)$'

      SCHEMA = {
        'type' => 'object',
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
      uses Middleware::OAuthClientProvider
      uses Middleware::GCClientProvider
      uses Middleware::StoreProvider

      requires :oauth_client
      requires :gc_client
      requires :store

      def call
        slack_user_id = params.fetch('user_id')
        message       = params.fetch('text')

        if message == 'authorise'
          handle_authorise_message(slack_user_id)
        else
          handle_payment_message(slack_user_id, message)
        end
      end

      private

      def handle_authorise_message(slack_user_id)
        url   = oauth_client.authorise_url(slack_user_id)
        label = 'Click me!'

        response = "<#{url}|#{label}>"

        [200, {}, [response]]
      end

      def handle_payment_message(slack_user_id, message)
        slack_user = store.find_slack_user(slack_user_id)

        return [200, {}, ['You need to authorise first!']] unless slack_user

        access_token = slack_user.fetch(:gc_access_token)
        currency, pence, email = parse_message(message)

        gc_client.create_payment(currency, pence, email, access_token)

        [200, {}, ['success!']]
      end

      CURRENCIES = {
        '£' => 'GBP',
        '€' => 'EUR'
      }

      def parse_message(message)
        amount, email = message.split(' from ')
        currency, *pounds = amount.chars
        currency = CURRENCIES.fetch(currency)
        pence = (BigDecimal.new(pounds.join) * 100).to_i

        [currency, pence, email]
      end
    end
  end
end
