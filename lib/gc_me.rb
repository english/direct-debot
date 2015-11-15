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
    store = DB::Store.new(db)
    uri   = URI.parse(Prius.get(:host))

    oauth_client = build_oauth_client(uri)

    router = build_router(uri, store, oauth_client)

    router
  end

  def self.build_router(uri, store, oauth_client)
    opts = { host: uri.host, scheme: uri.scheme, force_ssl: uri.scheme == 'https' }

    index_handler          = build_index_handler
    slack_messages_handler = build_slack_messages_handler(store, oauth_client)
    gc_callback_handler    = build_gc_callback_handler(store, oauth_client)

    Lotus::Router.new(opts) do
      get '/', to: index_handler
      post '/api/slack/messages', to: slack_messages_handler
      get '/api/gc/callback', to: gc_callback_handler
    end
  end

  def self.build_oauth_client(uri)
    redirect_uri = "#{uri}/api/gc/callback"

    OAuthClient.new(Prius, redirect_uri)
  end

  def self.build_index_handler
    Coach::Handler.new(Routes::Index)
  end

  def self.build_slack_messages_handler(store, oauth_client)
    Coach::Handler.new(Routes::SlackMessages,
                       store: store,
                       gc_environment: Prius.get(:gc_environment).to_sym,
                       oauth_client: oauth_client)
  end

  def self.build_gc_callback_handler(store, oauth_client)
    Coach::Handler.new(Routes::GCCallback,
                       store: store,
                       oauth_client: oauth_client)
  end
end
