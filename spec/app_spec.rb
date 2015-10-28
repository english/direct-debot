require_relative '../app'
require 'rack/request'

RSpec.describe APP do
  it 'handles /' do
    app = Rack::MockRequest.new(APP)

    response = app.get("https://#{Prius.get(:host)}/")

    expect(response.status).to eq(200)
  end

  it 'handles /api/slack/messages' do
    app = Rack::MockRequest.new(APP)

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
    expect(response.body).to include('https://gc-me-local.herokuapp.com/authorise')
  end
end
