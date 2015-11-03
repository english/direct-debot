require 'rack/request'
require 'sequel'
require 'webmock/rspec'
require 'prius'
require_relative '../../lib/gc_me'

RSpec.describe 'GC oauth callback' do
  subject!(:gc_me) { Rack::MockRequest.new(GCMe.build(db)) }

  let(:db) { Sequel.connect(Prius.get(:database_url)) }
  let(:base_url) { "https://#{Prius.get(:host)}" }

  it 'handles /api/gc/callback' do
    request_body = {
      client_id: 'gc_client_id',
      client_secret: 'gc_client_secret',
      code: '6NJiqXzT7HcgEGsAZXUmaBfB',
      grant_type: 'authorization_code',
      redirect_uri: 'https://gc-me.test/api/gc/callback'
    }

    response_body = {
      access_token: 'e72e16c7e42f292c6912e7710c123347ae178b4a',
      scope: 'full_access',
      token_type: 'bearer',
      organisation_id: 'OR123'
    }

    request = stub_request(:post, 'https://connect.gocardless.test/oauth/access_token').
      with(body: request_body).
      to_return(status: 200, body: response_body.to_json, headers: {
                  'Content-Type' => 'application/json'
                })

    expect do
      url = "#{base_url}/api/gc/callback?" \
            'code=6NJiqXzT7HcgEGsAZXUmaBfB&&state=q8wEr9yMohTP'
      response = gc_me.get(url)

      expect(response.body).to include('Gotcha!')
    end.to change { GCMe::DB::Store.new(db).count_slack_users! }.by(1)

    expect(request).to have_been_requested
  end
end
