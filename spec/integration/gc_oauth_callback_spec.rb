# frozen_string_literal: true

require 'webmock/rspec'
require_relative '../support/test_request'
require_relative '../support/transaction'
require_relative '../../lib/direct_debot'
require_relative '../../lib/direct_debot/system'

RSpec.describe 'GC oauth callback' do
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

  let!(:gc_auth_token_request) do
    request_body = {
      client_id: 'gc_client_id',
      client_secret: 'gc_client_secret',
      code: '6NJiqXzT7HcgEGsAZXUmaBfB',
      grant_type: 'authorization_code',
      redirect_uri: 'https://direct-debot.test/api/gc/callback'
    }

    response_body = {
      access_token: 'e72e16c7e42f292c6912e7710c123347ae178b4a',
      scope: 'full_access',
      token_type: 'bearer',
      organisation_id: 'OR123'
    }

    stub_request(:post, 'https://connect.gocardless.test/oauth/access_token').
      with(body: request_body).
      to_return(status: 200, body: response_body.to_json, headers: {
                  'Content-Type' => 'application/json'
                })
  end

  it 'handles /api/gc/callback' do
    expect {
      response = app.
        get('/api/gc/callback?code=6NJiqXzT7HcgEGsAZXUmaBfB&&state=q8wEr9yMohTP')

      expect(response.body).to include('Gotcha!')
    }.to change { store.count_users! }.by(1)

    expect(gc_auth_token_request).to have_been_requested
  end
end
