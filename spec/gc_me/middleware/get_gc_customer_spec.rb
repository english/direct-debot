# frozen_string_literal: true

require 'hamster'
require_relative '../../../lib/direct_debot/middleware/get_gc_customer'
require_relative '../../../lib/direct_debot/gc_client'
require_relative '../../../lib/direct_debot/payment_message'

RSpec.describe DirectDebot::Middleware::GetGCCustomer do
  subject { described_class.new(context, null_middleware) }

  let(:context) { { gc_client: gc_client, payment_message: payment_message } }
  let(:gc_client) { instance_double(DirectDebot::GCClient) }
  let(:payment_message) do
    Hamster::Hash.new(currency: 'GBP', amount: 1, email: 'someone@example.com')
  end

  context 'when the customer exists' do
    let(:customer) { double }

    before do
      expect(gc_client).
        to receive(:get_customer).
        with('someone@example.com').
        and_return(customer)
    end

    it { is_expected.to provide(gc_customer: customer) }
  end

  context 'when the customer does not exist' do
    before do
      expect(gc_client).
        to receive(:get_customer).
        with('someone@example.com').
        and_return(nil)
    end

    it { is_expected.to respond_with_body_that_matches('not a customer') }
  end
end
