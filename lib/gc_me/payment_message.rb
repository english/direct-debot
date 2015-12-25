# frozen_string_literal: true

require 'bigdecimal'

# Parses a 'payment message' from slack, e.g.
#   PaymentMessage.parse("£10 from someone@example.com")
#     # => PaymentMessage(currency: "£", pence: "1000", email: "someone@exmaple.com")
module GCMe
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
