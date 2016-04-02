# frozen_string_literal: true

require 'coach'
require 'hamster'
require_relative '../../middleware/get_gc_access_token'
require_relative '../../refinements/hash_slice'

module DirectDebot
  module Routes
    module SlackMessages
      # If the message is 'add jane@example.com'
      class HandleAddCustomer < Coach::Middleware
        using Refinements::HashSlice

        # verify slack user has authorised
        uses Middleware::GetGCAccessToken, -> (config) { config.slice!(:store, :host) }

        def call
          mail_queue, host = config.fetch_values(:mail_queue, :host)

          text, user_name, user_id = params.fetch_values('text', 'user_name', 'user_id')
          email = text.split(' ').last

          mail_queue << AddCustomerMail.build(email, user_name, user_id, host)

          [200, {}, ["Authorisation from #{email} has been requested."]]
        end

        # Provides a hash representation of the email message sent to prospective
        # customers
        module AddCustomerMail
          FROM    = 'noreply@direct-debot.test'
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
