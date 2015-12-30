# frozen_string_literal: true

require 'prius'
require_relative '../../config/prius'
require 'hamster'
require_relative 'db/component'
require_relative 'mail_component'
require_relative 'oauth_component'
require_relative 'server_component'

module GCMe
  # Configures and manages the lifecycle of potentially stateful components.
  class System
    def self.build
      new(Hamster::Hash.new(
            db_component: GCMe::DB::Component.new(Prius.get(:database_url)),
            oauth_component: build_oauth_component,
            mail_component: build_mail_component,
            server_component: build_server_component))
    end

    private_class_method def self.build_oauth_component
      GCMe::OAuthComponent.new(
        gc_client_id: Prius.get(:gc_client_id),
        gc_client_secret: Prius.get(:gc_client_secret),
        gc_connect_url: Prius.get(:gc_connect_url),
        gc_connect_authorize_path: Prius.get(:gc_connect_authorize_path),
        gc_connect_access_token_path: Prius.get(:gc_connect_access_token_path))
    end

    private_class_method def self.build_mail_component
      GCMe::MailComponent.build(
        delivery_method: Prius.get(:mail_delivery_method),
        input_queue: Queue.new,
        output_queue: Queue.new,
        user_name: Prius.get(:sendgrid_username),
        password: Prius.get(:sendgrid_password))
    end

    private_class_method def self.build_server_component
      GCMe::ServerComponent.new(Prius.get(:host),
                                Prius.get(:gc_environment),
                                Prius.get(:slack_token))
    end

    def initialize(component_hash)
      @component_hash = component_hash
    end

    def fetch(key)
      @component_hash.fetch(key)
    end

    def start
      @component_hash.each_value(&:start)
    end

    def stop
      @component_hash.each_value(&:stop)
    end
  end
end
