# frozen_string_literal: true

require 'webmock/rspec'
require_relative '../support/test_request'
require_relative '../support/transaction'
require_relative '../../lib/gc_me'
require_relative '../../lib/gc_me/system'
require_relative '../../lib/gc_me/db/store'

RSpec.describe 'adding a GoCardless customer' do
  let(:system) { GCMe::System.build }
  let(:store) { GCMe::DB::Store.new(system.fetch(:db).database) }

  around do |example|
    system.start
    Transaction.with_rollback(system, &example)
    system.stop
  end

  subject(:app) do
    TestRequest.new(system.fetch(:web_server).rack_app, system)
  end

  before do
    store.create_user!(slack_user_id: 'U123',
                       organisation_id: 'OR123',
                       gc_access_token: 'AT123')
  end

  context 'for the merchant adding a customer' do
    it 'sends an email to the recipient' do
      response = app.post('/api/slack/messages', text: 'customers add foo@bar.com')

      expect(response.status).to eq(200)
      expect(response.body).
        to include('Authorisation from foo@bar.com has been requested.')

      mail = system.fetch(:mail).output_queue.pop

      expect(mail[:from]).to eq('noreply@gc-me.test')
      expect(mail[:to]).to eq('foo@bar.com')
      expect(mail[:body].to_s).
        to eq('jamie wants to setup a direct debit with you. ' \
              'Authorise at https://gc-me.test/add-customer?user_id=U123.')
    end
  end

  context 'when the customer follows the given link' do
    let!(:redirect_flows_request) do
      request_body = {
        redirect_flows: {
          session_token: '1',
          success_redirect_url: 'https://gc-me.test/api/gc/add-customer-success'
        }
      }

      response_body = {
        redirect_flows: {
          id: 'RE123',
          description: nil,
          session_token: '1',
          scheme: nil,
          success_redirect_url: 'https://gc-me.test/api/gc/add-customer-success',
          redirect_url: 'https://pay.gocardless.com/flow/RE123',
          created_at: '2014-10-22T13:10:06.000Z',
          links: { creditor: 'CR123' }
        }
      }

      stub_request(:post, 'https://api-sandbox.gocardless.com/redirect_flows').
        with(body: request_body).
        to_return(status: 201, body: response_body.to_json,
                  headers: { 'Content-Type' => 'application/json' })
    end

    it 'sets up, and redirects to, a redirect flow' do
      response = app.get('/add-customer?user_id=U123')

      expect(response.status).to eq(302)
      expect(response.location).to eq('https://pay.gocardless.com/flow/RE123')
      expect(redirect_flows_request).to have_been_requested
    end
  end

  context 'when the customer completes the redirect flow' do
    let!(:confirm_redirec_flows_request) do
      request_body = { data: { session_token: '1' } }

      response_body = {
        redirect_flows: {
          id: 'RE123',
          description: nil,
          session_token: '1',
          scheme: nil,
          success_redirect_url: 'https://gc-me.test/api/gc/add-customer-success',
          redirect_url: 'https://pay.gocardless.com/flow/RE123',
          created_at: '2014-10-22T13:10:06.000Z',
          links: {
            creditor: 'CR123',
            mandate: 'MA123',
            customer: 'CU123',
            customer_bank_account: 'BA123'
          }
        }
      }

      stub_request(:post,
                   'https://api-sandbox.gocardless.com/redirect_flows/RF123/actions/complete').
        with(body: request_body).
        to_return(status: 200, body: response_body.to_json,
                  headers: { 'Content-Type' => 'application/json' })
    end

    it 'confirms the redirect flow' do
      store.create_redirect_flow!('U123', 'RF123')

      response = app.get('/api/gc/add-customer-success?redirect_flow_id=RF123')

      expect(response.status).to eq(200)
      expect(response.body).to include('boom')
    end
  end
end
