# frozen_string_literal: true

require 'bigdecimal'
require 'hamster'

module GCMe
  # Parses a 'payment message' from slack, e.g.
  #   PaymentMessage.parse("£10 from someone@example.com")
  #     # => { currency: "£", pence: "1000", email: "someone@exmaple.com" }
  module PaymentMessage
    CURRENCIES = Hamster::Hash.new(
      '£' => 'GBP',
      '€' => 'EUR'
    )

    def self.parse(string)
      amount, email = string.split(' from ')
      currency, *pounds = amount.chars

      Hamster::Hash.new(
        currency: CURRENCIES.fetch(currency),
        pence: (BigDecimal.new(pounds.join) * 100).to_i,
        email: email
      )
    end
  end
end
