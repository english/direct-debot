require_relative '../application'
require 'rack/request'

RSpec.describe Application do
  subject(:app) { Rack::MockRequest.new(Application.build) }

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
                      '&initial_view=signup' \
                      '&redirect_uri=' \
                        'https%3A%2F%2Fgc-me.test%2Fapi%2Fgc%2Fcallback' \
                      '&response_type=code' \
                      '&scope=full_access>'

    expect(response.body).to include(expected_body)
  end
end
