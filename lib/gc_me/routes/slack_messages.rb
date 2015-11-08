require 'coach'
require_relative '../middleware/gc_client_provider'
require_relative '../middleware/get_gc_access_token'
require_relative '../middleware/get_gc_mandate'
require_relative '../middleware/json_schema'
require_relative '../middleware/oauth_client_provider'
require_relative '../middleware/parse_payment_message'
require_relative '../middleware/store_provider'

module GCMe
  # Middlewares and route handler that process 'authorise' and 'payment' messages
  module Routes
    # If the message is 'authorise'
    class HandleAuthorize < Coach::Middleware
      uses Middleware::OAuthClientProvider

      requires :oauth_client

      def call
        message = params.fetch('text')

        return next_middleware.call unless message == 'authorise'

        url  = oauth_client.authorise_url(params.fetch('user_id'))
        body = SlackLink.new(url, 'Click me!').to_s

        [200, {}, [body]]
      end
    end

    SlackLink = Struct.new(:url, :label) do
      def to_s
        "<#{url}|#{label}>"
      end
    end

    # Assumes that the message text is a 'payment' one and processes it accordingly by
    # creating a payment
    class HandlePayment < Coach::Middleware
      uses Middleware::GCClientProvider
      uses Middleware::ParsePaymentMessage
      uses Middleware::GetGCMandate

      requires :gc_client
      requires :payment_message
      requires :gc_mandate

      def call
        gc_client.create_payment(gc_mandate, payment_message.currency,
                                 payment_message.pence)

        [200, {}, ['success!']]
      end
    end

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
      uses HandleAuthorize
      uses HandlePayment
    end
  end
end
