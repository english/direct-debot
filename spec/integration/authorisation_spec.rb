require_relative '../support/test_request'
require_relative '../../lib/gc_me'

RSpec.describe 'authorisation' do
  subject(:gc_me) { TestRequest.new(GCMe.build(@db)) }

  it 'handles /api/slack/messages with authorise' do
    response = gc_me.post('/api/slack/messages', text: 'authorise')

    expect(response.status).to eq(200)
    expect(response.body).
      to match(%r{connect\.gocardless\.test/oauth/authorize.+Click me})
  end
end
