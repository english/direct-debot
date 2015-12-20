require 'webmock/rspec'
require 'prius'
require 'mail'
require_relative '../support/test_request'
require_relative '../../lib/gc_me'
require_relative '../../lib/gc_me/db/store'

RSpec.describe 'adding a GoCardless customer' do
  subject!(:gc_me) { TestRequest.new(GCMe.build(@db)) }

  before do
    store = GCMe::DB::Store.new(@db)
    store.create_slack_user!(slack_user_id: 'U123', gc_access_token: 'AT123')

    GCMe::MailClient::Test.clear!
  end

  context 'for the merchant adding a customer' do
    it 'sends an email to the recipient' do
      response = nil

      expect { response = gc_me.post('/api/slack/messages', text: 'add foo@bar.com') }.
        to change { GCMe::MailClient::Test.deliveries.length }.
        by(1)

      expect(response.status).to eq(200)
      expect(response.body).
        to include('Authorisation from foo@bar.com has been requested.')

      mail = GCMe::MailClient::Test.deliveries.last
      expect(mail[:from]).to eq('noreply@gc-me.test')
      expect(mail[:to]).to eq('foo@bar.com')
      expect(mail[:body].to_s).
        to eq('jamie wants to setup a direct debit with you. ' \
              'Authorise at https://gc-me.test/add-customer?user=U123.')
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
      response = gc_me.get('/add-customer?user_id=U123')

      expect(response.status).to eq(302)
      expect(response.location).to eq('https://pay.gocardless.com/flow/RE123')
      expect(redirect_flows_request).to have_been_requested
    end
  end
end
