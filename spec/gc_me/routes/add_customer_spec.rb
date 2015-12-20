require 'gocardless_pro'
require_relative '../../../lib/gc_me/routes/add_customer'
require_relative '../../../lib/gc_me/gc_client'

RSpec.describe GCMe::Routes::AddCustomer do
  subject(:add_customer) do
    GCMe::Routes::AddCustomer.new({ gc_client: gc_client }, nil,
                                  success_url: 'https://foo.bar/baz')
  end

  let(:gc_client) { instance_double(GCMe::GCClient, create_redirect_flow: redirect_flow) }

  let(:redirect_flow) do
    instance_double(GoCardlessPro::Resources::RedirectFlow,
                    redirect_url: 'https://foo.bar/baz')
  end

  it 'creates a redirect flow' do
    status, headers, _body = subject.call

    expect(status).to eq(302)
    expect(headers['Location']).to eq('https://foo.bar/baz')
  end
end
