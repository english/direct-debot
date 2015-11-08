require 'active_support/concern'
require 'action_dispatch/http/request'
require_relative '../../../lib/gc_me/middleware/parse_payment_message'

RSpec.describe GCMe::Middleware::ParsePaymentMessage do
  it 'provides a parsed payment message' do
    next_middleware = double
    params          = { 'text' => '£10 from someone@example.com' }
    request         = instance_double(ActionDispatch::Request, params: params)
    context         = { request: request }

    subject = GCMe::Middleware::ParsePaymentMessage.new(context, next_middleware)

    expect(next_middleware).to receive(:call)

    expect(subject).to receive(:provide) do |provides|
      payment_message = provides.fetch(:payment_message)

      expect(payment_message.currency).to eq('GBP')
      expect(payment_message.pence).to eq(1000)
      expect(payment_message.email).to eq('someone@example.com')
    end

    subject.call
  end
end
