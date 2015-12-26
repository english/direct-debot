# frozen_string_literal: true

require 'hamster'
require_relative '../../../lib/gc_me/middleware/get_gc_customer'
require_relative '../../../lib/gc_me/gc_client'
require_relative '../../../lib/gc_me/payment_message'

RSpec.describe GCMe::Middleware::GetGCCustomer do
  let(:next_middleware) { double }
  let(:gc_client) { instance_double(GCMe::GCClient) }
  let(:payment_message) do
    Hamster::Hash.new(currency: 'GBP', amount: 1, email: 'someone@example.com')
  end
  let(:context) { { gc_client: gc_client, payment_message: payment_message } }

  subject { described_class.new(context, next_middleware) }

  context 'when the customer exists' do
    let(:customer) { double }

    before do
      expect(gc_client).
        to receive(:get_customer).
        with('someone@example.com').
        and_return(customer)
    end

    it 'provides the customer from the GC api' do
      expect(next_middleware).to receive(:call)

      expect(subject).
        to receive(:provide).
        with(gc_customer: customer)

      subject.call
    end
  end

  context 'when the customer does not exist' do
    before do
      expect(gc_client).
        to receive(:get_customer).
        with('someone@example.com').
        and_return(nil)
    end

    it 'responds with an error message' do
      expect(next_middleware).to_not receive(:call)
      expect(subject).to_not receive(:provide)

      _status, _headers, body = subject.call

      expect(body.first).to include('not a customer')
    end
  end
end
