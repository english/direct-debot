require 'webmock/rspec'
require_relative '../../lib/gc_me'
require_relative '../../lib/gc_me/db/store'
require_relative '../support/test_request'

RSpec.describe 'creating a payment' do
  subject(:gc_me) { TestRequest.new(GCMe.build(@db)) }

  before do
    store = GCMe::DB::Store.new(@db)
    store.create_slack_user!(slack_user_id: 'U123', gc_access_token: 'AT123')
  end

  let!(:customers_request) do
    customers_response = {
      customers: [{ id: 'CU123', email: 'jamie@gocardless.com' }]
    }.to_json

    stub_request(:get, 'https://api-sandbox.gocardless.com/customers').
      to_return(status: 200, body: customers_response, headers: {
                  'Content-Type' => 'application/json'
                })
  end

  let!(:mandates_request) do
    mandates_response = { mandates: [{ id: 'MA123', status: 'active' }] }.to_json

    stub_request(:get, 'https://api-sandbox.gocardless.com/mandates?customer=CU123').
      to_return(status: 200, body: mandates_response, headers: {
                  'Content-Type' => 'application/json'
                })
  end

  let!(:payment_request) do
    payments_response = { payments: { id: 'PA123' } }.to_json

    payments_body = {
      payments: { amount: 500, currency: 'GBP', links: { mandate: 'MA123' } }
    }.to_json

    stub_request(:post, 'https://api-sandbox.gocardless.com/payments').
      with(body: payments_body).
      to_return(status: 201, body: payments_response, headers: {
                  'Content-Type' => 'application/json'
                })
  end

  it 'handles /api/slack/messages with a payment message' do
    response = gc_me.post('/api/slack/messages', text: '£5 from jamie@gocardless.com')

    expect(response.status).to eq(200)

    expect(response.body).to include('success!')

    expect(customers_request).to have_been_made
    expect(mandates_request).to have_been_made
    expect(payment_request).to have_been_made
  end
end
