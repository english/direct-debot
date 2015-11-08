require 'gocardless_pro'
require_relative '../../lib/gc_me/gc_client'

RSpec.describe GCMe::GCClient do
  def build_customer(attrs)
    instance_double(GoCardlessPro::Resources::Customer, attrs)
  end

  def build_mandate(attrs)
    instance_double(GoCardlessPro::Resources::Mandate, attrs)
  end

  def build_list_response(records)
    instance_double(GoCardlessPro::ListResponse, records: records)
  end

  it 'gets an active mandates' do
    pro_client        = instance_double(GoCardlessPro::Client)
    customer          = build_customer(id: 'CU123')
    active_mandate    = build_mandate(status: 'active')
    cancelled_mandate = build_mandate(status: 'cancelled')
    mandates          = build_list_response([active_mandate, cancelled_mandate])

    expect(pro_client).
      to receive_message_chain(:mandates, :list).
      with(params: { customer: 'CU123' }).
      and_return(mandates)

    gc_client = GCMe::GCClient.new(pro_client)

    expect(gc_client.get_active_mandate(customer)).to eq(active_mandate)
  end

  it 'gets a customer' do
    pro_client = instance_double(GoCardlessPro::Client)
    customer   = build_customer(email: 'someone@example.com')
    customers  = build_list_response([customer])

    expect(pro_client).
      to receive_message_chain(:customers, :list).
      and_return(customers)

    gc_client = GCMe::GCClient.new(pro_client)

    expect(gc_client.get_customer('someone@example.com')).to eq(customer)
  end

  it 'creates payments' do
    pro_client = instance_double(GoCardlessPro::Client)
    mandate    = build_mandate(id: 'MA123')

    expect(pro_client).
      to receive_message_chain(:payments, :create).
      with(params: { amount: 1, currency: 'GBP', links: { mandate: 'MA123' } })

    gc_client = GCMe::GCClient.new(pro_client)
    gc_client.create_payment(mandate, 'GBP', 1)
  end
end
