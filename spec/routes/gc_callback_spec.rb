require 'active_support/concern'
require 'action_dispatch/http/request'
require 'oauth2'
require 'uri'
require 'lotus/router'
require_relative '../../routes/gc_callback'
require_relative '../../db/store'

RSpec.describe Routes::GCCallback do
  subject(:gc_callback) { Routes::GCCallback.new(context) }

  let(:context) do
    {
      request: instance_double(ActionDispatch::Request, params: params),
      oauth_client: oauth_client,
      store: store,
      router: router
    }
  end

  let(:params) { { 'code' => 'the-code', 'state' => 'slack-user-id' } }
  let(:oauth_client) { instance_double(OAuth2::Client, auth_code: auth_code_strategy) }
  let(:store) { instance_double(DB::Store) }
  let(:router) { instance_double(Lotus::Router) }
  let(:auth_code_strategy) { instance_double(OAuth2::Strategy::AuthCode) }
  let(:access_token) { instance_double(OAuth2::AccessToken, token: 'gc-token') }

  it 'creates a Store with a gc_access_token and store_id' do
    allow(router).
      to receive(:url).
      with(:gc_callback).
      and_return('https://gc-me.test:80/api/gc_callback')

    expect(auth_code_strategy).
      to receive(:get_token).
      with('the-code', redirect_uri: 'https://gc-me.test/api/gc_callback').
      and_return(access_token)

    expect(store).
      to receive(:create_slack_user!).
      with(gc_access_token: 'gc-token', slack_user_id: 'slack-user-id')

    status, _headers, _body = gc_callback.call

    expect(status).to eq(200)
  end
end
