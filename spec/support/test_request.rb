# frozen_string_literal: true

require 'rack/request'
require 'prius'

class TestRequest
  DEFAULT_PARAMS = {
    token: Prius.get(:slack_token),
    team_id: 'T0001',
    team_domain: 'example',
    channel_id: 'C2147483705',
    channel_name: 'test',
    user_id: 'U123',
    user_name: 'jamie',
    command: '/gc-me'
  }

  def initialize(app)
    @app = Rack::MockRequest.new(app)
    @host = Prius.get(:host)
  end

  def post(path, params)
    @app.post(@host + path, params: DEFAULT_PARAMS.merge(params))
  end

  def get(path)
    @app.get(@host + path)
  end
end
