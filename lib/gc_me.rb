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
    Application.new(db).rack_app
  end

  # Provides the GCMe rack application
  class Application
    INDEX_PATH          = '/'
    SLACK_MESSAGES_PATH = '/api/slack/messages'
    GC_CALLBACK_PATH    = '/api/gc/callback'

    def initialize(db)
      @store        = DB::Store.new(db)
      @host         = URI.parse(Prius.get(:host))
      @environment  = Prius.get(:gc_environment).to_sym
      @oauth_client = build_oauth_client
    end

    def rack_app
      opts = {
        host: @host.host,
        scheme: @host.scheme,
        force_ssl: @host.scheme == 'https'
      }

      Lotus::Router.new(opts).tap do |router|
        router.get(INDEX_PATH, to: Coach::Handler.new(Routes::Index))
        router.get(GC_CALLBACK_PATH, to: build_gc_callback_handler)
        router.post(SLACK_MESSAGES_PATH, to: build_slack_messages_handler)
      end
    end

    private

    def build_oauth_client
      redirect_uri = "#{@host}#{GC_CALLBACK_PATH}"

      OAuthClient.new(Prius, redirect_uri)
    end

    def build_slack_messages_handler
      Coach::Handler.new(Routes::SlackMessages,
                         store: @store,
                         gc_environment: @environment,
                         oauth_client: @oauth_client)
    end

    def build_gc_callback_handler
      Coach::Handler.new(Routes::GCCallback,
                         store: @store,
                         oauth_client: @oauth_client)
    end
  end
end
