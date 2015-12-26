# frozen_string_literal: true

require_relative '../../lib/gc_me/payment_message'

RSpec.describe GCMe::PaymentMessage do
  it 'parses a string message' do
    message = '£10 from someone@example.com'

    subject = described_class.parse(message)

    expect(subject.to_h).to eq(
      currency: 'GBP',
      pence: 1000,
      email: 'someone@example.com'
    )
  end
end
