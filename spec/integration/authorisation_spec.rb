require 'rack/request'
require 'sequel'
require 'prius'
require_relative '../../lib/gc_me'

RSpec.describe 'authorisation' do
  subject!(:gc_me) { Rack::MockRequest.new(GCMe.build(db)) }

  let(:db) { RSpec.configuration.db }
  let(:base_url) { "https://#{Prius.get(:host)}" }

  it 'handles /api/slack/messages with authorise' do
    response = gc_me.post("#{base_url}/api/slack/messages", params: {
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
                      '&scope=full_access' \
                      '&state=U2147483697|Click me!>'

    expect(response.body).to include(expected_body)
  end
end
