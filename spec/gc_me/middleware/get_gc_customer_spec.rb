require_relative '../../../lib/gc_me/middleware/get_gc_customer'
require_relative '../../../lib/gc_me/gc_client'
require_relative '../../../lib/gc_me/middleware/parse_payment_message'

RSpec.describe GCMe::Middleware::GetGCCustomer do
  context 'when the customer exists' do
    it 'provides the customer from the GC api' do
      next_middleware = double
      gc_client       = instance_double(GCMe::GCClient)
      payment_message =
        GCMe::Middleware::ParsePaymentMessage::PaymentMessage.new('GBP', 1,
                                                                  'someone@example.com')
      context         = { gc_client: gc_client, payment_message: payment_message }
      customer        = double

      subject = GCMe::Middleware::GetGCCustomer.new(context, next_middleware)

      expect(gc_client).
        to receive(:get_customer).
        with('someone@example.com').
        and_return(customer)

      expect(next_middleware).to receive(:call)

      expect(subject).
        to receive(:provide).
        with(gc_customer: customer)

      subject.call
    end
  end

  context 'when the customer does not exist' do
    it 'responds with an error message' do
      next_middleware = double
      gc_client       = instance_double(GCMe::GCClient)
      payment_message =
        GCMe::Middleware::ParsePaymentMessage::PaymentMessage.new('GBP', 1,
                                                                  'someone@example.com')
      context         = { gc_client: gc_client, payment_message: payment_message }

      subject = GCMe::Middleware::GetGCCustomer.new(context, next_middleware)

      expect(gc_client).
        to receive(:get_customer).
        with('someone@example.com').
        and_return(nil)

      expect(next_middleware).to_not receive(:call)

      expect(subject).to_not receive(:provide)

      _status, _headers, body = subject.call

      expect(body.first).to include('not a customer')
    end
  end
end
