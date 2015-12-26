# frozen_string_literal: true

require 'gocardless_pro'
require_relative '../../../lib/gc_me/routes/add_customer'
require_relative '../../../lib/gc_me/gc_client'
require_relative '../../../lib/gc_me/db/store'

RSpec.describe GCMe::Routes::AddCustomer do
  let(:store) { instance_double(GCMe::DB::Store) }

  subject(:add_customer) do
    context = { gc_client: gc_client, request: double(params: { user_id: 'US123' }) }
    config  = { store: store, success_url: 'https://foo.bar/baz' }

    described_class.new(context, nil, config)
  end

  let(:gc_client) { instance_double(GCMe::GCClient, create_redirect_flow: redirect_flow) }

  let(:redirect_flow) do
    instance_double(GoCardlessPro::Resources::RedirectFlow,
                    id: 'RF123',
                    redirect_url: 'https://foo.bar/baz')
  end

  it 'creates a GoCardless redirect flow' do
    expect(store).
      to receive(:create_redirect_flow!).
      with('US123', 'RF123')

    status, headers, _body = subject.call

    expect(status).to eq(302)
    expect(headers['Location']).to eq('https://foo.bar/baz')
  end
end
