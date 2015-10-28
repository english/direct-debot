require 'lotus/router'
require 'coach'

class Provider < Coach::Middleware
  provides :router

  def call
    provide(router: request.env.fetch('injected.router'))
    next_middleware.call
  end
end

# Just so we know the app is running and listening
class Index < Coach::Middleware
  def call
    [200, {}, ['hello world!']]
  end
end

# Handles Slack messages in the format of
#   /gc-me <amount> from <user>
# or
#   /gc-me authorise
class SlackMessages < Coach::Middleware
  uses Provider

  requires :router

  def call
    message = "Visit #{authorise_url} to authorise!"

    [200, {}, [message]]
  end

  private

  def authorise_url
    uri = URI(router.url(:authorise))

    # strip port from url
    uri.to_s.sub(":#{uri.port}", "")
  end
end

router = Lotus::Router.new(force_ssl: true, scheme: 'https', host: Prius.get(:host)) do
  get '/', to: Coach::Handler.new(Index)
  get '/authorise', as: :authorise
  post '/api/slack/messages', to: Coach::Handler.new(SlackMessages)
end

class Injector
  def initialize(app, config)
    @app = app
    @config = config
  end

  def call(env)
    env = @config.inject(env) { |h, (k, v)| h.merge("injected.#{k}" => v) }

    @app.call(env)
  end
end

APP = Rack::Builder.new do
  use Injector, "router": router
  run router
end
