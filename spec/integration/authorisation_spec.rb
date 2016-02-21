# frozen_string_literal: true

require_relative '../support/test_request'
require_relative '../support/transaction'
require_relative '../../lib/gc_me'
require_relative '../../lib/gc_me/system'

RSpec.describe 'authorisation' do
  let(:system) { GCMe::System.build }

  around do |example|
    system.start

    Transaction.with_rollback(system) do
      example.call
    end

    system.stop
  end

  subject(:app) { TestRequest.new(GCMe::Application.new(system).rack_app, system) }

  it 'handles /api/slack/messages with authorise' do
    response = app.post('/api/slack/messages', text: 'authorise')

    expect(response.status).to eq(200)
    expect(response.body).
      to match(%r{connect\.gocardless\.test/oauth/authorize.+Click me})
  end
end
