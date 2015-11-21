require_relative '../../lib/gc_me/payment_message'

RSpec.describe GCMe::PaymentMessage do
  it 'parses a string message' do
    message = '£10 from someone@example.com'

    subject = GCMe::PaymentMessage.parse(message)

    expect(subject.currency).to eq('GBP')
    expect(subject.pence).to eq(1000)
    expect(subject.email).to eq('someone@example.com')
  end
end
