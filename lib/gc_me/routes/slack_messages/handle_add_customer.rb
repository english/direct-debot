# frozen_string_literal: true

require 'coach'
require 'hamster'
require_relative '../../middleware/get_gc_access_token'
require_relative '../../refinements/hash_slice'

module GCMe
  module Routes
    module SlackMessages
      # If the message is 'add jane@example.com'
      class HandleAddCustomer < Coach::Middleware
        using Refinements::HashSlice

        # verify slack user has authorised
        uses Middleware::GetGCAccessToken, -> (config) { config.slice!(:store, :host) }

        def call
          mail_client, host = config.fetch_values(:mail_client, :host)
          text, user_name, user_id = params.fetch_values('text', 'user_name', 'user_id')
          prefix, email = text.split(' ')

          return next_middleware.call unless prefix == 'add'

          mail = AddCustomerMail.build(email, user_name, user_id, host)
          mail_client.deliver!(mail)

          [200, {}, ["Authorisation from #{email} has been requested."]]
        end

        # Provides a hash representation of the email message sent to prospective
        # customers
        module AddCustomerMail
          FROM    = 'noreply@gc-me.test'
          SUBJECT = 'Setup a direct debit with %s'
          BODY    = '%s wants to setup a direct debit with you. Authorise at %s.'

          def self.build(to, user_name, user_id, host)
            url = "#{host}/add-customer?user_id=#{user_id}"

            Hamster::Hash.new(
              from:    FROM,
              to:      to,
              subject: format(SUBJECT, user_name),
              body:    format(BODY, user_name, url)
            )
          end
        end
      end
    end
  end
end
