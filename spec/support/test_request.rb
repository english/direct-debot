# frozen_string_literal: true

require 'rack/request'

class TestRequest
  DEFAULT_PARAMS = {
    team_id: 'T0001',
    team_domain: 'example',
    channel_id: 'C2147483705',
    channel_name: 'test',
    user_id: 'U123',
    user_name: 'jamie',
    command: '/direct-debot'
  }

  def initialize(app, system)
    @app = Rack::MockRequest.new(app)
    @system = system
    @slack_token = Prius.get(:slack_token)
  end

  def post(path, params)
    @app.post(host + path, params: { token: @slack_token, **DEFAULT_PARAMS, **params })
  end

  def get(path)
    @app.get(host + path)
  end

  private

  def host
    @system.fetch(:web_server).host.to_s
  end
end
