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
            webhook: build_webhook,
            slack: build_slack))
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
      @components = components
    end

    def fetch(key)
      @components.fetch(key)
    end

    def start
      sort_by_dependencies(@components).each_value do |component|
        if component.class.respond_to?(:depends_on)
          dependencies = component_dependencies(component, @components)
          component.start(*dependencies)
        else
          component.start
        end
      end
    end

    def stop
      sort_by_dependencies(@components).
        values.
        reverse_each(&:stop)
    end

    private

    def sort_by_dependencies(components)
      in_starting_order = DependencyMap.new(components).sort

      in_starting_order.reduce({}) do |memo, klass|
        name, inst = components.find { |(_k, v)| v.is_a?(klass) }

        memo.merge(name => inst)
      end
    end

    def component_dependencies(component, system)
      dependencies = component.class.depends_on

      dependencies.
        map { |(klass, _attr)| system.values.find { |inst| inst.is_a?(klass) } }.
        compact
    end
  end

  # Allows a system map to be sorted in dependency order
  class DependencyMap
    include TSort

    def initialize(components)
      @components = components_and_dependencies(components)
    end

    alias sort tsort

    private

    def tsort_each_node(&block)
      @components.each_key(&block)
    end

    def tsort_each_child(node, &block)
      @components.fetch(node).each(&block)
    end

    def components_and_dependencies(components)
      components.values.reduce({}) do |memo, instance|
        if instance.class.respond_to?(:depends_on)
          memo.merge(instance.class => instance.class.depends_on)
        else
          memo.merge(instance.class => [])
        end
      end
    end
  end
end
