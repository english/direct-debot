require 'lotus/router'
require 'coach'
require 'prius'
require_relative 'gc_me/middleware/injector'
require_relative 'gc_me/routes/index'
require_relative 'gc_me/routes/slack_messages'
require_relative 'gc_me/routes/gc_callback'
require_relative 'gc_me/routes/add_customer'
require_relative 'gc_me/routes/add_customer_success'
require_relative 'gc_me/db/store'
require_relative 'gc_me/oauth_client'
require_relative 'gc_me/gc_client'
require_relative 'gc_me/mail_client'

# This is where the magic happens
module GCMe
  def self.build(db)
    Application.new(db).rack_app
  end

  # Provides the GCMe rack application
  class Application
    INDEX_PATH                = '/'
    SLACK_MESSAGES_PATH       = '/api/slack/messages'
    GC_CALLBACK_PATH          = '/api/gc/callback'
    ADD_CUSTOMER_PATH         = '/add-customer'
    ADD_CUSTOMER_SUCCESS_PATH = '/api/gc/add-customer-success'

    def initialize(db)
      @store        = DB::Store.new(db)
      @host         = URI.parse(Prius.get(:host))
      @environment  = Prius.get(:gc_environment).to_sym
      @slack_token  = Prius.get(:slack_token)
      @oauth_client = build_oauth_client
      @mail_client  = build_mail_client
    end

    # rubocop:disable Metrics/AbcSize
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
      end
    end
    # rubocop:enable Metrics/AbcSize

    private

    def build_oauth_client
      redirect_uri = "#{@host}#{GC_CALLBACK_PATH}"

      OAuthClient.new(Prius, redirect_uri)
    end

    def build_mail_client
      GCMe::MailClient.build(Prius.get(:mail_delivery_method),
                             Prius.get(:sendgrid_username),
                             Prius.get(:sendgrid_password))
    end

    def build_slack_messages_handler
      Coach::Handler.new(Routes::SlackMessages::Handler,
                         store: @store,
                         gc_environment: @environment,
                         oauth_client: @oauth_client,
                         mail_client: @mail_client,
                         slack_token: @slack_token)
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
  end
end
