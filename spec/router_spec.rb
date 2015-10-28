require_relative '../router'
require 'rack/request'

RSpec.describe Router do
  it 'handles /' do
    app = Rack::MockRequest.new(Router)

    response = app.get('/')

    expect(response.status).to eq(200)
  end

  it 'handles /api-slack/gc-me' do
    app = Rack::MockRequest.new(Router)

    response = app.get('/')

    expect(response.status).to eq(200)
  end
end
