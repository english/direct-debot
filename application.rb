require 'lotus/router'
require 'coach'
require_relative 'lib/oauth_client'
require_relative 'middleware/injector'
require_relative 'routes/index'
require_relative 'routes/slack_messages'
require_relative 'routes/gc_callback'

# This is where the magic happens
module Application
  def self.build
    router = build_router
    oauth_client = OauthClient.build

    Rack::Builder.new do
      use Middleware::Injector, router: router, oauth_client: oauth_client
      run router
    end
  end

  private_class_method def self.build_router
    opts = { host: Prius.get(:host) }

    unless Prius.get(:rack_env) == 'development'
      opts.merge!(force_ssl: true, scheme: 'https')
    end

    Lotus::Router.new(opts) do
      get '/', to: Coach::Handler.new(Routes::Index)
      post '/api/slack/messages', to: Coach::Handler.new(Routes::SlackMessages)
      get '/api/gc/callback', to: Coach::Handler.new(Routes::GCCallback), as: :gc_callback
    end
  end
end
