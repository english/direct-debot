require 'coach'
require_relative 'gc_client_provider'
require_relative 'parse_payment_message'

module GCMe
  module Middleware
    # Fetches the GC customer by email.
    # If the customer doesn't exist, and error message is returned
    class GetGCCustomer < Coach::Middleware
      uses Middleware::GCClientProvider
      uses Middleware::ParsePaymentMessage

      requires :gc_client
      requires :payment_message

      provides :gc_customer

      def call
        gc_customer = gc_client.get_customer(payment_message.email)

        if gc_customer
          provide(gc_customer: gc_customer)
          next_middleware.call
        else
          [200, {}, ["#{payment_message.email} is not a customer of yours!"]]
        end
      end
    end
  end
end
