# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'development'

require 'prius'
require 'tsort'
require 'hamster'
require 'oauth2'
require_relative 'components/db'
require_relative 'components/mail'
require_relative 'components/airbrake'
require_relative 'components/logger'
require_relative 'components/webhook'
require_relative 'components/slack'
require_relative 'components/web_server'
require_relative 'components/fakes/slack_server'

module GCMe
  # Configures and manages the lifecycle of potentially stateful components.
  # rubocop:disable Metrics/ClassLength
  class System
    def self.build
      load_config!

      new(Hamster::Hash.new(
            db: build_db,
            mail: [build_mail, :logger],
            airbrake: build_airbrake,
            logger: build_logger,
            webhook: [build_webhook, :logger, :db, :slack],
            slack: [build_slack, :logger],
            web_server: [build_web_server, :db, :mail, :webhook, :slack]))
    end

    def self.build_dev
      load_config!

      new(Hamster::Hash.new(
            db: build_db,
            mail: [build_mail, :logger],
            airbrake: build_airbrake,
            logger: build_logger,
            webhook: [build_webhook, :logger, :db, :slack],
            slack: [build_slack, :logger],
            fake_slack: [build_fake_slack, :logger],
            web_server: [build_web_server, :db, :mail, :webhook, :slack]))
    end

    def self.load_config!
      if ENV['RACK_ENV'] == 'development'
        require 'dotenv'
        Dotenv.load
      end

      require_relative '../../config/prius'
    end

    private_class_method def self.build_db
      GCMe::Components::DB.new(Prius.get(:database_url), Prius.get(:thread_count))
    end

    private_class_method def self.build_oauth_client
      connection_opts = { request: { timeout: 1 } }

      OAuth2::Client.new(
        Prius.get(:gc_client_id),
        Prius.get(:gc_client_secret),
        site: Prius.get(:gc_connect_url),
        authorize_url: Prius.get(:gc_connect_authorize_path),
        token_url: Prius.get(:gc_connect_access_token_path),
        connection_opts: connection_opts)
    end

    private_class_method def self.build_mail
      GCMe::Components::Mail.build(
        delivery_method: Prius.get(:mail_delivery_method),
        user_name: Prius.get(:sendgrid_username),
        password: Prius.get(:sendgrid_password))
    end

    private_class_method def self.build_airbrake
      GCMe::Components::Airbrake.new(Prius.get(:airbrake_project_id),
                                     Prius.get(:airbrake_api_key))
    end

    private_class_method def self.build_logger
      GCMe::Components::Logger.new(Prius.get(:log_path))
    end

    private_class_method def self.build_webhook
      GCMe::Components::Webhook.new(Prius.get(:gc_webhook_secret),
                                    Prius.get(:gc_environment).to_sym)
    end

    private_class_method def self.build_slack
      GCMe::Components::Slack.new(Prius.get(:slack_bot_api_token),
                                  Prius.get(:slack_message_url),
                                  Prius.get(:slack_token))
    end

    private_class_method def self.build_web_server
      GCMe::Components::WebServer.new(Prius.get(:thread_count),
                                      Prius.get(:port),
                                      Prius.get(:host),
                                      Prius.get(:gc_environment),
                                      build_oauth_client)
    end

    private_class_method def self.build_fake_slack
      GCMe::Components::Fakes::SlackServer.new(Prius.get(:slack_message_url))
    end

    def initialize(components)
      @components = components.map { |(k, v)| [k, Array(v)] }.to_h
    end

    def fetch(compoenent_key)
      @components.fetch(compoenent_key).first
    end

    def start
      sort_by_dependencies(@components).
        map(&method(:fetch_component_with_dependent_components)).
        each { |(component, dependencies)| component.start(*dependencies) }
    end

    def stop
      sort_by_dependencies(@components).
        reverse.
        map(&method(:fetch)).
        each(&:stop)
    end

    private

    def fetch_component_with_dependent_components(component_key)
      component, *dependency_keys = *@components.fetch(component_key)

      [component, dependency_keys.map(&method(:fetch))]
    end

    def sort_by_dependencies(components)
      dependency_map = components.map { |(name, component_and_dependencies)|
        [name, Array(component_and_dependencies[1..-1])]
      }.to_h

      TSortableHash.new(dependency_map).tsort
    end
  end
  # rubocop:enable Metrics/ClassLength

  # Allows a hash to be sorted in dependency order
  class TSortableHash
    include TSort

    def initialize(hash)
      @hash = hash
    end

    private

    def tsort_each_node(&block)
      @hash.each_key(&block)
    end

    def tsort_each_child(node, &block)
      @hash.fetch(node).each(&block)
    end
  end
end
