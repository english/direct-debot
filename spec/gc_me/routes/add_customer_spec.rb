# frozen_string_literal: true

require 'gocardless_pro'
require_relative '../../../lib/direct_debot/routes/add_customer'
require_relative '../../../lib/direct_debot/gc_client'
require_relative '../../../lib/direct_debot/db/store'

RSpec.describe DirectDebot::Routes::AddCustomer do
  let(:store) { instance_double(DirectDebot::DB::Store) }

  subject(:add_customer) do
    context = { gc_client: gc_client, request: double(params: { user_id: 'US123' }) }
    config  = { store: store, success_url: 'https://foo.bar/baz' }

    described_class.new(context, nil, config)
  end

  let(:gc_client) do
    instance_double(DirectDebot::GCClient, create_redirect_flow: redirect_flow)
  end

  let(:redirect_flow) do
    instance_double(GoCardlessPro::Resources::RedirectFlow,
                    id: 'RF123',
                    redirect_url: 'https://foo.bar/baz')
  end

  before do
    expect(store).
      to receive(:create_redirect_flow!).
      with('US123', 'RF123')
  end

  it { is_expected.to respond_with_status(302) }
  it { is_expected.to respond_with_header('Location', 'https://foo.bar/baz') }
end
