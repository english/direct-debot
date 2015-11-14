require 'rack/request'
require 'sequel'
require 'webmock/rspec'
require 'prius'
require_relative '../../lib/gc_me'
require_relative '../../lib/gc_me/db/store'

RSpec.describe 'creating a payment' do
  subject!(:gc_me) { Rack::MockRequest.new(GCMe.build(db)) }

  let(:db) { RSpec.configuration.db }
  let(:base_url) { "https://#{Prius.get(:host)}" }
  let(:store) { GCMe::DB::Store.new(db) }

  it 'handles /api/slack/messages with a payment message' do
    store.create_slack_user!(slack_user_id: 'U2147483697',
                             gc_access_token: 'gc-access-token')

    customers_response = {
      customers: [{ id: 'CU123', email: 'jamie@gocardless.com' }]
    }.to_json

    customers_request = stub_request(:get, 'https://api-sandbox.gocardless.com/customers').
      to_return(status: 200, body: customers_response, headers: {
                  'Content-Type' => 'application/json'
                })

    mandates_response = { mandates: [{ id: 'MA123', status: 'active' }] }.to_json

    mandates_request =
      stub_request(:get, 'https://api-sandbox.gocardless.com/mandates?customer=CU123').
        to_return(status: 200, body: mandates_response, headers: {
                    'Content-Type' => 'application/json'
                  })

    payments_response = { payments: { id: 'PA123' } }.to_json

    payments_body = {
      payments: { amount: 500, currency: 'GBP', links: { mandate: 'MA123' } }
    }.to_json
    payment_request = stub_request(:post, 'https://api-sandbox.gocardless.com/payments').
      with(body: payments_body).
      to_return(status: 201, body: payments_response, headers: {
                  'Content-Type' => 'application/json'
                })

    response = gc_me.post("#{base_url}/api/slack/messages", params: {
                            token: 'L8v9uEsAb7tLOct7FLovRBEU',
                            team_id: 'T0001',
                            team_domain: 'example',
                            channel_id: 'C2147483705',
                            channel_name: 'test',
                            user_id: 'U2147483697',
                            user_name: 'Steve',
                            command: '/gc-me',
                            text: '£5 from jamie@gocardless.com'
                          })

    expect(response.status).to eq(200)

    expected_body = 'success!'

    expect(response.body).to include(expected_body)

    expect(customers_request).to have_been_made
    expect(mandates_request).to have_been_made
    expect(payment_request).to have_been_made
  end
end
