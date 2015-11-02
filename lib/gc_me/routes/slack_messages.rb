require 'coach'
require_relative '../middleware/oauth_client_provider'
require_relative '../middleware/store_provider'
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
      uses Middleware::StoreProvider

      requires :oauth_client
      requires :store

      CURRENCIES = {
        '£' => 'GBP',
        '€' => 'EUR'
      }

      def call
        slack_user_id = params.fetch('user_id')

        message = params.fetch('text')

        if message == 'authorise'
          url = oauth_client.authorise_url(slack_user_id)
          label = 'Click me!'
          payload = "<#{url}|#{label}>"

          [200, {}, [payload]]
        else
          slack_user = store.find_slack_user(params.fetch('user_id'))

          if slack_user
            amount, recipient = message.split(' from ')
            currency, *amount = amount.chars
            currency = CURRENCIES.fetch(currency)
            pence = (BigDecimal.new(amount.join) * 100).to_i

            client = GoCardlessPro::Client.new(access_token: slack_user.fetch(:gc_access_token))

            customer = client.customers.list.records.
              find { |customer| customer.email == recipient }

            mandate = client.
              mandates.
              list(params: { customer: customer.id }).
              records.
              first

            client.payments.create(amount: pence, currency: currency, links: { mandate: mandate.id })

            [200, {}, ['success!']]
          else
            [200, {}, ['You need to authorise first!']]
          end
        end
      end
    end
  end
end
