require 'lotus/router'
require 'sequel'
require 'coach'
require 'prius'
require_relative 'gc_me/middleware/injector'
require_relative 'gc_me/routes/index'
require_relative 'gc_me/routes/slack_messages'
require_relative 'gc_me/routes/gc_callback'
require_relative 'gc_me/db/store'
require_relative 'gc_me/oauth_client'
require_relative 'gc_me/gc_client'

# This is where the magic happens
module GCMe
  def self.build(db)
    store        = DB::Store.new(db)
    router       = build_router(store)
    oauth_client = build_oauth_client(router)

    Rack::Builder.new do
      use Middleware::Injector, oauth_client: oauth_client,
                                store: store
      run router
    end
  end

  private_class_method def self.build_router(store)
    opts = { host: Prius.get(:host) }

    unless Prius.get(:rack_env) == 'development'
      opts.merge!(force_ssl: true, scheme: 'https')
    end

    Lotus::Router.new(opts) do
      get '/', to: Coach::Handler.new(Routes::Index)
      post '/api/slack/messages',
           to: Coach::Handler.new(Routes::SlackMessages,
                                  store: store,
                                  gc_environment: Prius.get(:gc_environment).to_sym)
      get '/api/gc/callback',
          to: Coach::Handler.new(Routes::GCCallback, store: store),
          as: :gc_callback
    end
  end

  private_class_method def self.build_oauth_client(router)
    # strip port from url
    redirect_uri = URI.
      parse(router.url(:gc_callback)).
      tap { |uri| uri.port = nil }.
      to_s

    OAuthClient.new(Prius, redirect_uri)
  end
end
