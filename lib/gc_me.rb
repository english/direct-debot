# frozen_string_literal: true

require 'lotus/router'
require 'coach'
require 'prius'
require 'hamster'
require_relative 'gc_me/routes/index'
require_relative 'gc_me/routes/slack_messages'
require_relative 'gc_me/routes/gc_callback'
require_relative 'gc_me/routes/add_customer'
require_relative 'gc_me/routes/add_customer_success'
require_relative 'gc_me/routes/gc_webhooks'
require_relative 'gc_me/db/store'
require_relative 'gc_me/oauth_client'

# This is where the magic happens
module GCMe
  # Provides the GCMe rack application
  class Application
    INDEX_PATH                = '/'
    SLACK_MESSAGES_PATH       = '/api/slack/messages'
    GC_CALLBACK_PATH          = '/api/gc/callback'
    ADD_CUSTOMER_PATH         = '/add-customer'
    ADD_CUSTOMER_SUCCESS_PATH = '/api/gc/add-customer-success'
    GC_WEBHOOKS_PATH          = '/api/gc/webhooks'

    def self.from_system(system)
      new(
        system.fetch(:db),
        system.fetch(:server_configuration),
        system.fetch(:oauth),
        system.fetch(:mail),
        system.fetch(:webhook)
      )
    end

    def initialize(db, server_configuration, oauth, mail, webhook)
      @store = DB::Store.new(db.database)
      @server_configuration = server_configuration
      @oauth_client = build_oauth_client(oauth)
      @mail = mail
      @webhook = webhook
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def rack_app
      opts = { host: @server_configuration.host.host,
               scheme: @server_configuration.host.scheme,
               force_ssl: @server_configuration.host.scheme == 'https' }

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
      redirect_uri = "#{@server_configuration.host}#{GC_CALLBACK_PATH}"

      OAuthClient.new(oauth.client, redirect_uri)
    end

    def build_slack_messages_handler
      Coach::Handler.new(Routes::SlackMessages::Handler,
                         store: @store,
                         gc_environment: @server_configuration.environment,
                         oauth_client: @oauth_client,
                         mail_queue: @mail.input_queue,
                         slack_token: @server_configuration.slack_token,
                         host: @server_configuration.host)
    end

    def build_add_customer_handler
      success_url = "#{@server_configuration.host}#{ADD_CUSTOMER_SUCCESS_PATH}"

      Coach::Handler.new(Routes::AddCustomer,
                         store: @store,
                         gc_environment: @server_configuration.environment,
                         success_url: success_url)
    end

    def build_add_customer_success_handler
      Coach::Handler.new(Routes::AddCustomerSuccess::Handler,
                         store: @store,
                         gc_environment: @server_configuration.environment)
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
