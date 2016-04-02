# frozen_string_literal: true

require_relative '../support/test_request'
require_relative '../support/transaction'
require_relative '../../lib/direct_debot'
require_relative '../../lib/direct_debot/system'

RSpec.describe 'authorisation' do
  let(:system) { DirectDebot::System.build }

  around do |example|
    system.start
    Transaction.with_rollback(system, &example)
    system.stop
  end

  subject(:app) do
    TestRequest.new(system.fetch(:web_server).rack_app, system)
  end

  it 'handles /api/slack/messages with authorise' do
    response = app.post('/api/slack/messages', text: 'authorise')

    expect(response.status).to eq(200)
    expect(response.body).
      to match(%r{connect\.gocardless\.test/oauth/authorize.+Click me})
  end
end
