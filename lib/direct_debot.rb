# frozen_string_literal: true

require 'lotus/router'
require 'coach'
require 'prius'
require 'hamster'
require_relative 'direct_debot/routes/index'
require_relative 'direct_debot/routes/slack_messages'
require_relative 'direct_debot/routes/gc_callback'
require_relative 'direct_debot/routes/add_customer'
require_relative 'direct_debot/routes/add_customer_success'
require_relative 'direct_debot/routes/gc_webhooks'
require_relative 'direct_debot/db/store'
require_relative 'direct_debot/oauth_client'

# This is where the magic happens
module DirectDebot
  # Provides the DirectDebot rack application
  class Application
    INDEX_PATH                = '/'
    SLACK_MESSAGES_PATH       = '/api/slack/messages'
    GC_CALLBACK_PATH          = '/api/gc/callback'
    ADD_CUSTOMER_SUCCESS_PATH = '/api/gc/add-customer-success'
    GC_WEBHOOKS_PATH          = '/api/gc/webhooks'
    ADD_CUSTOMER_PATH         = '/add-customer'

    # rubocop:disable Metrics/ParameterLists
    def initialize(db, mail, webhook, slack, web_server, oauth)
      @store = DB::Store.new(db.database)
      @host = web_server.host
      @environment = web_server.environment
      @slack_token = slack.slack_token
      @mail = mail
      @webhook = webhook
      @oauth_client = build_oauth_client(oauth)
    end
    # rubocop:enable Metrics/ParameterLists

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def rack_app
      opts = { host: @host.host,
               scheme: @host.scheme,
               force_ssl: @host.scheme == 'https' }

      Lotus::Router.new(opts).tap do |router|
        router.get(INDEX_PATH, to: Coach::Handler.new(Routes::Index))
        router.get(GC_CALLBACK_PATH, to: build_gc_callback_handler)
        router.post(SLACK_MESSAGES_PATH, to: build_slack_messages_handler)
        router.get(ADD_CUSTOMER_PATH, to: build_add_customer_handler)
        router.get(ADD_CUSTOMER_SUCCESS_PATH, to: build_add_customer_success_handler)
        router.post(GC_WEBHOOKS_PATH, to: build_gc_webhooks_handler)
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    private

    def build_oauth_client(oauth)
      redirect_uri = "#{@host}#{GC_CALLBACK_PATH}"

      OAuthClient.new(oauth, redirect_uri)
    end

    def build_slack_messages_handler
      Coach::Handler.new(Routes::SlackMessages::Handler,
                         store: @store,
                         gc_environment: @environment,
                         oauth_client: @oauth_client,
                         mail_queue: @mail.input_queue,
                         slack_token: @slack_token,
                         host: @host)
    end

    def build_add_customer_handler
      success_url = "#{@host}#{ADD_CUSTOMER_SUCCESS_PATH}"

      Coach::Handler.new(Routes::AddCustomer,
                         store: @store,
                         gc_environment: @environment,
                         success_url: success_url)
    end

    def build_add_customer_success_handler
      Coach::Handler.new(Routes::AddCustomerSuccess::Handler,
                         store: @store,
                         gc_environment: @environment)
    end

    def build_gc_callback_handler
      Coach::Handler.new(Routes::GCCallback,
                         store: @store,
                         oauth_client: @oauth_client)
    end

    def build_gc_webhooks_handler
      Coach::Handler.new(Routes::GCWebhooks,
                         gc_webhook_secret: @webhook.gc_webhook_secret,
                         queue: @webhook.input_queue)
    end
  end
end
