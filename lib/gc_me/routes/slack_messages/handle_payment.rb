# frozen_string_literal: true

require 'coach'
require_relative '../../middleware/get_gc_access_token'
require_relative '../../middleware/build_gc_client'
require_relative '../../middleware/parse_payment_message'
require_relative '../../middleware/get_gc_customer'
require_relative '../../middleware/get_gc_mandate'

module GCMe
  module Routes
    module SlackMessages
      # Assumes that the message text is a 'payment' one and processes it accordingly by
      # creating a payment
      class HandlePayment < Coach::Middleware
        uses Middleware::GetGCAccessToken, -> (config) { config.slice(:store) }

        uses Middleware::BuildGCClient,
             -> (config) { config.slice(:store, :gc_environment) }

        uses Middleware::ParsePaymentMessage
        uses Middleware::GetGCCustomer
        uses Middleware::GetGCMandate

        requires :gc_client
        requires :payment_message
        requires :gc_mandate

        def call
          currency, pence = payment_message.fetch_values(:currency, :pence)

          gc_client.create_payment(gc_mandate, currency, pence)

          [200, {}, ['success!']]
        end
      end
    end
  end
end
