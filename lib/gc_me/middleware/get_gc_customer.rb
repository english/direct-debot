# frozen_string_literal: true

require 'coach'

module GCMe
  module Middleware
    # Fetches the GC customer by email.
    # If the customer doesn't exist, and error message is returned
    class GetGCCustomer < Coach::Middleware
      requires :gc_client
      requires :payment_message

      provides :gc_customer

      def call
        email = payment_message.fetch(:email)
        gc_customer = gc_client.get_customer(email)

        if gc_customer
          provide(gc_customer: gc_customer)
          next_middleware.call
        else
          [200, {}, ["#{email} is not a customer of yours!"]]
        end
      end
    end
  end
end
