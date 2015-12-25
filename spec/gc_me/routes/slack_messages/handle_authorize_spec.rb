# frozen_string_literal: true

require_relative '../../../../lib/gc_me/routes/slack_messages/handle_authorize'
require_relative '../../../../lib/gc_me/oauth_client'

RSpec.describe GCMe::Routes::SlackMessages::HandleAuthorize do
  subject(:handle_authorize) do
    context = { request: double(params: params) }

    GCMe::Routes::SlackMessages::HandleAuthorize.new(context, next_middleware,
                                                     oauth_client: oauth_client)
  end

  let(:oauth_client) { instance_double(GCMe::OAuthClient) }
  let(:next_middleware) { -> () {} }

  context 'when given an authorise message' do
    let(:params) { { 'user_id' => 'slack-user-id', 'text' => 'authorise' } }

    it 'returns a gc oauth link' do
      expect(oauth_client).
        to receive(:authorize_url).
        with('slack-user-id').
        and_return('https://authorise-url')

      status, _headers, body = handle_authorize.call

      expect(status).to eq(200)
      expect(body.first).to eq('<https://authorise-url|Click me!>')
    end
  end

  context 'when not given an authorise message' do
    let(:params) { { 'user_id' => 'slack-user-id', 'text' => 'bla' } }

    it 'calls the next middleware' do
      expect(next_middleware).to receive(:call)
      handle_authorize.call
    end
  end
end
