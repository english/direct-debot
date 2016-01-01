# frozen_string_literal: true

require_relative '../../../../lib/gc_me/routes/slack_messages/handle_authorize'
require_relative '../../../../lib/gc_me/oauth_client'

RSpec.describe GCMe::Routes::SlackMessages::HandleAuthorize do
  subject(:handle_authorize) do
    context = { request: double(params: params) }

    described_class.new(context, null_middleware, oauth_client: oauth_client)
  end

  let(:oauth_client) { instance_double(GCMe::OAuthClient) }

  context 'when given an authorise message' do
    let(:params) { { 'user_id' => 'slack-user-id', 'text' => 'authorise' } }

    before do
      expect(oauth_client).
        to receive(:authorize_url).
        with('slack-user-id').
        and_return('https://authorise-url')
    end

    it do
      is_expected.
        to respond_with_body_that_matches('<https://authorise-url|Click me!>')
    end

    it { is_expected.to respond_with_status(200) }
  end
end
