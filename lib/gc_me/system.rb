# frozen_string_literal: true

require 'prius'
require_relative '../../config/prius'
require 'hamster'
require_relative 'components/db'
require_relative 'components/mail'
require_relative 'components/oauth'
require_relative 'components/server'
require_relative 'components/airbrake'

module GCMe
  # Configures and manages the lifecycle of potentially stateful components.
  class System
    def self.build
      new(Hamster::Hash.new(
            db_component: build_db_component,
            oauth_component: build_oauth_component,
            mail_component: build_mail_component,
            server_component: build_server_component,
            airbrake_component: build_airbrake_component))
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
                                   Prius.get(:slack_token))
    end

    private_class_method def self.build_airbrake_component
      GCMe::Components::Airbrake.new(Prius.get(:airbrake_project_id),
                                     Prius.get(:airbrake_api_key))
    end

    def initialize(components)
      @components = components
    end

    def fetch(key)
      @components.fetch(key)
    end

    def start
      @components = @components.reduce(Hamster::Hash.new) do |memo, (name, component)|
        memo.put(name, component.start)
      end
    end

    def stop
      @components = @components.reduce(Hamster::Hash.new) do |memo, (name, component)|
        memo.put(name, component.stop)
      end
    end
  end
end
