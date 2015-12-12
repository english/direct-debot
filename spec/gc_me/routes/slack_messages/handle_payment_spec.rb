require_relative '../../../../lib/gc_me/routes/slack_messages/handle_payment'
require_relative '../../../../lib/gc_me/gc_client'

RSpec.describe GCMe::Routes::SlackMessages::HandlePayment do
  it 'creates a payment' do
    gc_client       = instance_double(GCMe::GCClient)
    payment_message = double(currency: 'GBP', pence: 1)
    gc_mandate      = double

    slack_messages = GCMe::Routes::SlackMessages::HandlePayment.new(
      gc_client: gc_client,
      payment_message: payment_message,
      gc_mandate: gc_mandate)

    expect(gc_client).
      to receive(:create_payment).
      with(gc_mandate, 'GBP', 1)

    status, * = slack_messages.call

    expect(status).to eq(200)
  end
end
