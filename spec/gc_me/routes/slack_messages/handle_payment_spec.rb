# frozen_string_literal: true

require 'hamster'
require_relative '../../../../lib/direct_debot/routes/slack_messages/handle_payment'
require_relative '../../../../lib/direct_debot/gc_client'

RSpec.describe DirectDebot::Routes::SlackMessages::HandlePayment do
  subject(:route) do
    described_class.new(gc_client: gc_client,
                        payment_message: payment_message,
                        gc_mandate: gc_mandate)
  end

  let(:gc_client) { instance_double(DirectDebot::GCClient) }
  let(:payment_message) { Hamster::Hash.new(currency: 'GBP', pence: 1) }
  let(:gc_mandate) { double }

  before do
    expect(gc_client).
      to receive(:create_payment).
      with(gc_mandate, 'GBP', 1)
  end

  it { is_expected.to respond_with_status(200) }
end
