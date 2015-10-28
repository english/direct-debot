require_relative '../router'
require 'rack/request'

RSpec.describe Router do
  it 'handles /' do
    app = Rack::MockRequest.new(Router)

    response = app.get('/')

    expect(response.status).to eq(200)
  end

  it 'handles /api/slack/messages' do
    app = Rack::MockRequest.new(Router)

    response = app.post('/api/slack/messages', params: {
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
    expect(response.body).to eq('Visit https://gc-me-local.herokuapp.com to authorise!')
  end
end
