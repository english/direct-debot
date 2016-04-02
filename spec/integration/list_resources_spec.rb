# frozen_string_literal: true

require 'webmock/rspec'
require_relative '../support/test_request'
require_relative '../support/transaction'
require_relative '../../lib/direct_debot'
require_relative '../../lib/direct_debot/system'
require_relative '../../lib/direct_debot/db/store'

RSpec.describe 'adding a GoCardless customer' do
  let(:system) { DirectDebot::System.build }

  around do |example|
    system.start
    Transaction.with_rollback(system, &example)
    system.stop
  end

  subject(:app) do
    TestRequest.new(system.fetch(:web_server).rack_app, system)
  end

  let(:store) { DirectDebot::DB::Store.new(system.fetch(:db).database) }

  before do
    store.create_user!(slack_user_id: 'U123',
                       organisation_id: 'OR123',
                       gc_access_token: 'AT123')
  end

  context 'listing resources' do
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
      response = app.post('/api/slack/messages', text: 'customers list')

      expect(response.status).to eq(200)
      expect(response.body).to eq(<<-RESPONSE.chomp)
```
- id: CU123
  email: jamie@gocardless.com
```
      RESPONSE
    end
  end

  context 'showing a single resource' do
    let!(:customer_request) do
      customer_resource = {
        customers: { id: 'CU123', email: 'jamie@gocardless.com' }
      }.to_json

      stub_request(:get, 'https://api-sandbox.gocardless.com/customers/CU123').
        to_return(status: 200, body: customer_resource, headers: {
                    'Content-Type' => 'application/json'
                  })
    end

    it 'shows single GC resources' do
      response = app.post('/api/slack/messages', text: 'customers show CU123')

      expect(response.status).to eq(200)
      expect(response.body).to eq(<<-RESPONSE.chomp)
```
id: CU123
email: jamie@gocardless.com
```
      RESPONSE
    end
  end
end
