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
# require_relative 'components/webhook'

module GCMe
  # Configures and manages the lifecycle of potentially stateful components.
  class System
    def self.build
      new(Hamster::Hash.new(
            db_component: build_db_component,
            oauth_component: build_oauth_component,
            mail_component: build_mail_component,
            server_component: build_server_component,
            airbrake_component: build_airbrake_component,
            logger_component: build_logger_component,
            # webhook_component: build_webhook_component
            ))
    end

    private_class_method def self.build_db_component
      GCMe::Components::DB.new(Prius.get(:database_url), Prius.get(:thread_count))
    end

    private_class_method def self.build_oauth_component
      GCMe::Components::OAuth.new(
        gc_client_id: Prius.get(:gc_client_id),
        gc_client_secret: Prius.get(:gc_client_secret),
        gc_connect_url: Prius.get(:gc_connect_url),
        gc_connect_authorize_path: Prius.get(:gc_connect_authorize_path),
        gc_connect_access_token_path: Prius.get(:gc_connect_access_token_path))
    end

    private_class_method def self.build_mail_component
      GCMe::Components::Mail.build(
        delivery_method: Prius.get(:mail_delivery_method),
        input_queue: Queue.new,
        output_queue: Queue.new,
        user_name: Prius.get(:sendgrid_username),
        password: Prius.get(:sendgrid_password))
    end

    private_class_method def self.build_server_component
      GCMe::Components::Server.new(Prius.get(:host),
                                   Prius.get(:gc_environment),
                                   Prius.get(:slack_token),
                                   Prius.get(:slack_bot_api_token))
    end

    private_class_method def self.build_airbrake_component
      GCMe::Components::Airbrake.new(Prius.get(:airbrake_project_id),
                                     Prius.get(:airbrake_api_key))
    end

    private_class_method def self.build_logger_component
      GCMe::Components::Logger.new(Prius.get(:log_path))
    end

    # private_class_method def self.build_webhook_component
    #   GCMe::Components::Webhook.new(Queue.new, Prius.get(:slack_bot_api_token))
    # end

    def initialize(components)
      @components = components
    end

    def fetch(key)
      @components.fetch(key)
    end

    def start
      components = sort_by_dependencies(@components)

      @components = components.reduce(Hamster::Hash.new) do |memo, (name, component)|
        if component.class.respond_to?(:depends_on)
          dependencies = component.class.depends_on

          dependencies.each do |(klass, attr)|
            inst = memo.values.find { |inst| inst.is_a?(klass) }

            component.public_send("#{attr}=", inst)
          end
        end

        memo.put(name, component.start)
      end
    end

    def stop
      components = sort_by_dependencies(@components).to_a.reverse

      @components = components.reduce(Hamster::Hash.new) do |memo, (name, component)|
        memo.put(name, component.stop)
      end
    end

    private

    def sort_by_dependencies(components)
      components_and_dependencies = components.values.map do |instance|
        if instance.class.respond_to?(:depends_on)
          [instance.class, instance.class.depends_on.keys]
        else
          [instance.class, []]
        end
      end

      hash = Hash[components_and_dependencies]

      class << hash
        include TSort

        alias tsort_each_node each_key

        def tsort_each_child(node, &block)
          fetch(node).each(&block)
        end
      end

      in_starting_order = hash.tsort

      ordered_pairs = in_starting_order.map do |klass|
        name, inst = components.find { |(k, v)| v.is_a?(klass) }

        [name, inst]
      end

      ordered_pairs
    end
  end
end
