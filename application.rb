require 'lotus/router'
require 'oauth2'
require 'coach'
require 'prius'
require_relative 'middleware/injector'
require_relative 'routes/index'
require_relative 'routes/slack_messages'
require_relative 'routes/gc_callback'
require_relative 'db/store'

Sequel.extension(:migration)

# This is where the magic happens
module Application
  def self.build(db)
    router       = build_router
    oauth_client = build_oauth_client
    store        = DB::Store.new(db)

    Sequel::Migrator.run(db, 'db/migrations')

    Rack::Builder.new do
      use Middleware::Injector, router: router,
                                oauth_client: oauth_client,
                                store: store
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

  private_class_method def self.build_oauth_client
    client_id         = Prius.get(:gc_client_id)
    client_secret     = Prius.get(:gc_client_secret)
    connect_url       = Prius.get(:gc_connect_url)
    authorize_path    = Prius.get(:gc_connect_authorize_path)
    access_token_path = Prius.get(:gc_connect_access_token_path)

    OAuth2::Client.new(client_id, client_secret, site: connect_url,
                                                 authorize_url: authorize_path,
                                                 token_url: access_token_path)
  end
end
