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

  it 'sends a slack message to the recipient' do
    response = nil

    expect { response = gc_me.post('/api/slack/messages', text: 'add foo@bar.com') }.
      to change { GCMe::MailClient::Test.deliveries.length }.
      by(1)

    expect(response.status).to eq(200)
    expect(response.body).to include('Authorisation from foo@bar.com has been requested.')

    mail = GCMe::MailClient::Test.deliveries.last
    expect(mail[:from]).to eq('noreply@gc-me.test')
    expect(mail[:to]).to eq('foo@bar.com')
    expect(mail[:body].to_s).
      to eq('jamie wants to setup a direct debit with you. ' \
            'Authorise at https://gc-me.test/authorise/U123.')
  end
end
