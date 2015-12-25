# frozen_string_literal: true

require 'gocardless_pro'
require_relative '../../lib/gc_me/gc_client'

RSpec.describe GCMe::GCClient do
  def build_customer(attrs)
    instance_double(GoCardlessPro::Resources::Customer, attrs)
  end

  def build_mandate(attrs)
    instance_double(GoCardlessPro::Resources::Mandate, attrs)
  end

  let(:pro_client) { instance_double(GoCardlessPro::Client) }
  subject(:gc_client) { GCMe::GCClient.new(pro_client) }

  it 'gets an active mandates' do
    customer          = build_customer(id: 'CU123')
    active_mandate    = build_mandate(status: 'active')
    cancelled_mandate = build_mandate(status: 'cancelled')

    expect(pro_client).
      to receive_message_chain(:mandates, :all).
      with(params: { customer: 'CU123' }).
      and_return([active_mandate, cancelled_mandate])

    expect(gc_client.get_active_mandate(customer)).to eq(active_mandate)
  end

  it 'gets a customer' do
    customer = build_customer(email: 'someone@example.com')

    expect(pro_client).
      to receive_message_chain(:customers, :all).
      and_return([customer])

    expect(gc_client.get_customer('someone@example.com')).to eq(customer)
  end

  it 'creates payments' do
    mandate = build_mandate(id: 'MA123')

    expect(pro_client).
      to receive_message_chain(:payments, :create).
      with(params: { amount: 1, currency: 'GBP', links: { mandate: 'MA123' } })

    gc_client.create_payment(mandate, 'GBP', 1)
  end

  it 'creates a redirect flow' do
    redirect_url  = 'https://foo.bar/baz'
    redirect_flow = double

    expect(pro_client).
      to receive_message_chain(:redirect_flows, :create).
      with(params: { session_token: '1', success_redirect_url: redirect_url }).
      and_return(redirect_flow)

    expect(gc_client.create_redirect_flow(redirect_url)).to be(redirect_flow)
  end
end
