require 'coach'
require_relative '../../middleware/get_gc_access_token'

module GCMe
  module Routes
    module SlackMessages
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

        # Provides a hash representation of the email message sent to prospective
        # customers
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
    end
  end
end
