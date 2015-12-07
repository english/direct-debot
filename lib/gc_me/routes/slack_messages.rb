require 'coach'
require_relative '../middleware/gc_client_provider'
require_relative '../middleware/get_gc_access_token'
require_relative '../middleware/get_gc_customer'
require_relative '../middleware/get_gc_mandate'
require_relative '../middleware/json_schema'
require_relative '../middleware/parse_payment_message'
require_relative '../middleware/verify_slack_token'

module GCMe
  # Middlewares and route handler that process 'authorise' and 'payment' messages
  module Routes
    # If the message is 'add jane@example.com'
    class HandleAddCustomer < Coach::Middleware
      # verify slack user has authorised
      uses Middleware::GetGCAccessToken, -> (config) { config.slice(:store) }

      def call
        text, user_name, user_id = params.fetch_values('text', 'user_name', 'user_id')
        return next_middleware.call unless add_customer_message?(text)

        mail_client = config.fetch(:mail_client)
        email_address = text.split(' ').last

        message = AddCustomerMessage.build(email_address, user_name, user_id,
                                           Prius.get(:host))
        mail_client.deliver!(message)

        [200, {}, ["Authorisation from #{email_address} has been requested."]]
      end

      private

      def add_customer_message?(text)
        text.split(' ').first == 'add'
      end

      # Provides a hash representation of the email message sent to prospective customers
      module AddCustomerMessage
        FROM    = 'noreply@gc-me.test'
        SUBJECT = 'Setup a direct debit with %s'
        BODY    = '%s wants to setup a direct debit with you. Authorise at %s.'

        def self.build(to, user_name, user_id, host)
          authorisation_url = "#{host}/authorise/#{user_id}"

          {
            from:    FROM,
            to:      to,
            subject: format(SUBJECT, user_name),
            body:    format(BODY, user_name, authorisation_url)
          }
        end
      end
    end

    # If the message is 'authorise'
    class HandleAuthorize < Coach::Middleware
      def call
        oauth_client = config.fetch(:oauth_client)
        message, user_id = params.fetch_values('text', 'user_id')

        return next_middleware.call unless message == 'authorise'

        url  = oauth_client.authorise_url(user_id)
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
      uses Middleware::GetGCAccessToken, -> (config) { config.slice(:store) }

      uses Middleware::GCClientProvider,
           -> (config) { config.slice(:store, :gc_environment) }

      uses Middleware::ParsePaymentMessage
      uses Middleware::GetGCCustomer
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
      uses HandleAddCustomer, -> (config) { config.slice(:mail_client, :store) }
      uses HandlePayment, -> (config) { config.slice(:store, :gc_environment) }
    end
  end
end
