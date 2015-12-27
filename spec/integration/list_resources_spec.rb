# frozen_string_literal: true

require 'webmock/rspec'
require_relative '../support/test_request'
require_relative '../../lib/gc_me'
require_relative '../../lib/gc_me/db/store'

RSpec.describe 'adding a GoCardless customer' do
  subject!(:gc_me) { TestRequest.new(GCMe.build(@db)) }
  let(:store) { GCMe::DB::Store.new(@db) }

  before do
    store.create_user!(slack_user_id: 'U123', gc_access_token: 'AT123')

    GCMe::MailClient::Test.clear!
  end

  let!(:customers_request) do
    customers_response = {
      customers: [{ id: 'CU123', email: 'jamie@gocardless.com' }],
      meta: { cursors: { before: nil, after: nil } }
    }.to_json

    stub_request(:get, 'https://api-sandbox.gocardless.com/customers').
      to_return(status: 200, body: customers_response, headers: {
                  'Content-Type' => 'application/json'
                })
  end

  it "lists all of a user's GC resources" do
    response = gc_me.post('/api/slack/messages', text: 'list customers')

    expect(response.status).to eq(200)
    expect(response.body).to eq(<<-RESPONSE.chomp)
```
[
  {
    "id": "CU123",
    "email": "jamie@gocardless.com"
  }
]
```
    RESPONSE
  end
end
