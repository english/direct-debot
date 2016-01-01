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

  specify do
    properties = property_of { [choose('£', '€'), float, string] }

    properties.check do |(currency, pounds, email)|
      string = "#{currency}#{pounds} from #{email}"

      message = described_class.parse(string)

      expect(message[:currency]).to be_in(Set.new(%w(GBP EUR)))
      expect(message[:email]).to be_a(String)

      expect(message[:pence]).to be_a(Fixnum)
      expect(message[:pence] / 100.0).to be_within(0.01).of(pounds)
    end
  end
end
