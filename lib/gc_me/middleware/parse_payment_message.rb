require 'coach'
require_relative '../payment_message'

module GCMe
  module Middleware
    # Parses the payment request text into a struct of :currency, :pence and :email
    class ParsePaymentMessage < Coach::Middleware
      provides :payment_message

      def call
        text = params.fetch('text')

        provide(payment_message: PaymentMessage.parse(text))

        next_middleware.call
      end
    end
  end
end
