require 'rack/request'
require 'webmock/rspec'
require 'prius'
require_relative '../../lib/gc_me'
require_relative '../../lib/gc_me/db/store'

RSpec.describe 'adding a GoCardless customer' do
  subject!(:gc_me) { Rack::MockRequest.new(GCMe.build(@db)) }

  before do
    store = GCMe::DB::Store.new(@db)
    store.create_slack_user!(slack_user_id: 'U2147483697',
                             gc_access_token: 'gc-access-token')
  end

  it 'sends a slack message to the recipient' do
    mock_auth_message = MockSlackAuthorisationMessage.
      new(text: '@jamie wants to setup a direct debit with you. ' \
                '<https://google.com|Click here> to authorise.',
          user: '@jane')

    mock_auth_message_request = mock_auth_message.mock!

    request = TestRequest.new(gc_me)
    response = request.post('/api/slack/messages', text: 'add @jane')

    expect(response.status).to eq(200)
    expect(response.body).to include('Authorisation from @jane has been requested.')
    expect(mock_auth_message_request).to have_been_made
  end

  class TestRequest
    DEFAULT_PARAMS = {
      token: Prius.get(:slack_token),
      team_id: 'T0001',
      team_domain: 'example',
      channel_id: 'C2147483705',
      channel_name: 'test',
      user_id: 'U2147483697',
      user_name: 'jamie',
      command: '/gc-me'
    }

    def initialize(app)
      @app = app
      @host = Prius.get(:host)
    end

    def post(path, params)
      @app.post(@host + path, DEFAULT_PARAMS.merge(params))
    end
  end

  class MockSlackAuthorisationMessage
    def initialize(text:, user:)
      @request_body = {
        token: Prius.get(:slack_token),
        channel: user,
        text: text,
        username: 'gc-me'
      }
    end

    def mock!
      response_body    = { ok: true }.to_json
      response_headers = { 'Content-Type' => 'application/json' }

      WebMock.
        stub_request(:get, 'https://slack.com/api/chat.postMessage').
        with(body: @request_body).
        to_return(status: 200, body: response_body, headers: response_headers)
    end
  end
end
