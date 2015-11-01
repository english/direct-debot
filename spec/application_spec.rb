require 'rack/request'
require 'webmock'
require 'webmock/rspec'
require 'sequel'
require_relative '../application'
require_relative '../db/store'

RSpec.describe Application do
  subject!(:app) { Rack::MockRequest.new(Application.build(db)) }
  let(:db) { Sequel.connect(Prius.get(:database_url)) }

  it 'handles /' do
    response = app.get("https://#{Prius.get(:host)}/")

    expect(response.status).to eq(200)
  end

  it 'handles /api/slack/messages' do
    response = app.post("https://#{Prius.get(:host)}/api/slack/messages", params: {
                          token: 'L8v9uEsAb7tLOct7FLovRBEU',
                          team_id: 'T0001',
                          team_domain: 'example',
                          channel_id: 'C2147483705',
                          channel_name: 'test',
                          user_id: 'U2147483697',
                          user_name: 'Steve',
                          command: '/gc-me',
                          text: 'authorise'
                        })

    expect(response.status).to eq(200)

    expected_body = '<https://connect.gocardless.test/oauth/authorize' \
                      '?client_id=gc_client_id' \
                      '&initial_view=login' \
                      '&redirect_uri=' \
                        'https%3A%2F%2Fgc-me.test%2Fapi%2Fgc%2Fcallback' \
                      '&response_type=code' \
                      '&scope=full_access|Click me!>'

    expect(response.body).to include(expected_body)
  end

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
      url = "https://#{Prius.get(:host)}/api/gc/callback?" \
            'code=6NJiqXzT7HcgEGsAZXUmaBfB&&state=q8wEr9yMohTP'
      response = app.get(url)

      expect(response.body).to include('Gotcha!')
    end.to change { DB::Store.new(db).count_slack_users! }.by(1)

    expect(request).to have_been_requested
  end
end
