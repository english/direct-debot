require 'coach'

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

      PaymentMessage = Struct.new(:currency, :pence, :email) do
        CURRENCIES = {
          '£' => 'GBP',
          '€' => 'EUR'
        }

        def self.parse(string)
          amount, email = string.split(' from ')
          currency, *pounds = amount.chars
          currency = CURRENCIES.fetch(currency)
          pence = (BigDecimal.new(pounds.join) * 100).to_i

          new(currency, pence, email)
        end
      end
    end
  end
end
