# frozen_string_literal: true

require 'coach'

module DirectDebot
  module Middleware
    # Fetches the active GC mandate by customer.
    # If an active mandate doesn't exist, and error message is returned
    class GetGCMandate < Coach::Middleware
      requires :gc_customer
      requires :gc_client

      provides :gc_mandate

      def call
        gc_mandate = gc_client.get_active_mandate(gc_customer)

        if gc_mandate
          provide(gc_mandate: gc_mandate)
          next_middleware.call
        else
          [200, {}, ["#{gc_customer.email} does not have an active mandate!"]]
        end
      end
    end
  end
end
