# frozen_string_literal: true

require_relative '../../../lib/direct_debot/middleware/get_gc_mandate'
require_relative '../../../lib/direct_debot/gc_client'
require_relative '../../../lib/direct_debot/middleware/parse_payment_message'

RSpec.describe DirectDebot::Middleware::GetGCMandate do
  subject(:route) { described_class.new(context, null_middleware) }

  let(:context) { { gc_client: gc_client, gc_customer: customer } }
  let(:gc_client) { instance_double(DirectDebot::GCClient) }
  let(:customer) do
    instance_double(GoCardlessPro::Resources::Customer, email: 'someone@example.com')
  end

  context 'when the mandate exists' do
    let(:mandate) { double }

    before do
      expect(gc_client).
        to receive(:get_active_mandate).
        with(customer).
        and_return(mandate)
    end

    it { is_expected.to call_next_middleware }
    it { is_expected.to provide(gc_mandate: mandate) }
  end

  context 'when the mandate does not exist' do
    before do
      expect(gc_client).
        to receive(:get_active_mandate).
        with(customer).
        and_return(nil)
    end

    it { is_expected.to_not call_next_middleware }

    it do
      is_expected.to respond_with_body_that_matches(
        'someone@example.com does not have an active mandate')
    end
  end
end
