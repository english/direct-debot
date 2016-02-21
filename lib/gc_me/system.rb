# frozen_string_literal: true

require 'prius'
require 'tsort'
require_relative '../../config/prius'
require 'hamster'
require_relative 'components/db'
require_relative 'components/mail'
require_relative 'components/oauth'
require_relative 'components/server'
require_relative 'components/airbrake'
require_relative 'components/logger'
require_relative 'components/webhook'
require_relative 'components/slack'

module GCMe
  # Configures and manages the lifecycle of potentially stateful components.
  class System
    def self.build
      new(Hamster::Hash.new(
            db: build_db,
            oauth: build_oauth,
            mail: build_mail,
            server: build_server,
            airbrake: build_airbrake,
            logger: build_logger,
            webhook: [build_webhook, :logger, :db, :server, :slack],
            slack: [build_slack, :logger]))
    end

    private_class_method def self.build_db
      GCMe::Components::DB.new(Prius.get(:database_url), Prius.get(:thread_count))
    end

    private_class_method def self.build_oauth
      GCMe::Components::OAuth.new(
        gc_client_id: Prius.get(:gc_client_id),
        gc_client_secret: Prius.get(:gc_client_secret),
        gc_connect_url: Prius.get(:gc_connect_url),
        gc_connect_authorize_path: Prius.get(:gc_connect_authorize_path),
        gc_connect_access_token_path: Prius.get(:gc_connect_access_token_path))
    end

    private_class_method def self.build_mail
      GCMe::Components::Mail.build(
        delivery_method: Prius.get(:mail_delivery_method),
        input_queue: Queue.new,
        output_queue: Queue.new,
        user_name: Prius.get(:sendgrid_username),
        password: Prius.get(:sendgrid_password))
    end

    private_class_method def self.build_server
      GCMe::Components::Server.new(Prius.get(:host),
                                   Prius.get(:gc_environment),
                                   Prius.get(:slack_token))
    end

    private_class_method def self.build_airbrake
      GCMe::Components::Airbrake.new(Prius.get(:airbrake_project_id),
                                     Prius.get(:airbrake_api_key))
    end

    private_class_method def self.build_logger
      GCMe::Components::Logger.new(Prius.get(:log_path))
    end

    private_class_method def self.build_webhook
      GCMe::Components::Webhook.new(Queue.new, Prius.get(:gc_webhook_secret))
    end

    private_class_method def self.build_slack
      GCMe::Components::Slack.new(Queue.new, Prius.get(:slack_bot_api_token))
    end

    def initialize(components)
      @components = components.map { |(k, v)| [k, Array(v)] }.to_h
    end

    def fetch(key)
      @components.fetch(key).first
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
