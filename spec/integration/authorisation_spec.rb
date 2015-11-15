require 'rack/request'
require 'prius'
require_relative '../../lib/gc_me'

RSpec.describe 'authorisation' do
  subject!(:gc_me) { Rack::MockRequest.new(GCMe.build(@db)) }

  let(:base_url) { Prius.get(:host) }

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

    expect(response.body).
      to match(/connect\.gocardless\.test\/oauth\/authorize.+Click me/)
  end
end
