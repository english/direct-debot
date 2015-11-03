require 'gocardless_pro'
require_relative '../../lib/gc_me/gc_client'

RSpec.describe GCMe::GCClient do
  it 'creates payments' do
    gc_customers_service = instance_double(GoCardlessPro::Services::CustomersService)
    gc_mandates_service  = instance_double(GoCardlessPro::Services::MandatesService)
    gc_payments_service  = instance_double(GoCardlessPro::Services::PaymentsService)

    gc_client = instance_double(GoCardlessPro::Client, customers: gc_customers_service,
                                                       mandates: gc_mandates_service,
                                                       payments: gc_payments_service)

    expect(GoCardlessPro::Client).
      to receive(:new).
      with(environment: :live, access_token: 'access-token').
      and_return(gc_client)

    customer = instance_double(GoCardlessPro::Resources::Customer,
                               id: 'CU123',
                               email: 'someone@example.com')

    # TODO: paginate using `all`
    expect(gc_customers_service).
      to receive(:list).
      and_return(instance_double(GoCardlessPro::ListResponse, records: [customer]))

    mandate = instance_double(GoCardlessPro::Resources::Mandate, id: 'MD123')

    # TODO: paginate using `all`
    expect(gc_mandates_service).
      to receive(:list).
      with(params: { customer: 'CU123' }).
      and_return(instance_double(GoCardlessPro::ListResponse, records: [mandate]))

    expect(gc_payments_service).
      to receive(:create).
      with(params: { amount: 1000, currency: 'GBP', links: { mandate: 'MD123' } })

    GCMe::GCClient.new(:live).
      create_payment('GBP', 1000, 'someone@example.com', 'access-token')
  end
end
