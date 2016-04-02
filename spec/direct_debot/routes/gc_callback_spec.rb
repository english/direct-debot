# frozen_string_literal: true

require_relative '../../../lib/direct_debot/oauth_client'
require_relative '../../../lib/direct_debot/routes/gc_callback'
require_relative '../../../lib/direct_debot/db/store'
require 'hamster'

RSpec.describe DirectDebot::Routes::GCCallback do
  subject(:gc_callback) do
    context = { request: double(params: params) }

    described_class.new(context, nil, store: store, oauth_client: oauth_client)
  end

  let(:params) { { 'code' => 'the-code', 'state' => 'slack-user-id' } }
  let(:oauth_client) { instance_double(DirectDebot::OAuthClient) }
  let(:store) { instance_double(DirectDebot::DB::Store) }

  it 'persists a user with a gc_access_token, organisation_id and slack_user_id' do
    expect(oauth_client).
      to receive(:create_access_token!).
      with('the-code').
      and_return(Hamster::Hash.new(token: 'gc-token', organisation_id: 'OR123'))

    expect(store).
      to receive(:create_user!).
      with(gc_access_token: 'gc-token', organisation_id: 'OR123',
           slack_user_id: 'slack-user-id')

    expect(subject).to respond_with_status(200)
  end
end
