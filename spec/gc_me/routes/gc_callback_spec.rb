require 'active_support/concern'
require 'action_dispatch/http/request'
require_relative '../../../lib/gc_me/oauth_client'
require_relative '../../../lib/gc_me/routes/gc_callback'
require_relative '../../../lib/gc_me/db/store'

RSpec.describe GCMe::Routes::GCCallback do
  subject(:gc_callback) { GCMe::Routes::GCCallback.new(context) }

  let(:context) do
    {
      request: instance_double(ActionDispatch::Request, params: params),
      oauth_client: oauth_client,
      store: store
    }
  end

  let(:params) { { 'code' => 'the-code', 'state' => 'slack-user-id' } }
  let(:oauth_client) { instance_double(GCMe::OAuthClient) }
  let(:store) { instance_double(GCMe::DB::Store) }

  it 'creates a Store with a gc_access_token and store_id' do
    expect(oauth_client).
      to receive(:create_access_token!).
      with('the-code').
      and_return('gc-token')

    expect(store).
      to receive(:create_slack_user!).
      with(gc_access_token: 'gc-token', slack_user_id: 'slack-user-id')

    status, _headers, _body = gc_callback.call

    expect(status).to eq(200)
  end
end
