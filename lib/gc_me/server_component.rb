# frozen_string_literal: true

module GCMe
  # Poorly named, but holds configuration for 'server'y stuff. And a slack token...
  class ServerComponent
    attr_reader :host, :environment, :slack_token

    def initialize(host, environment, slack_token)
      @host = URI.parse(host)
      @environment = environment.to_sym
      @slack_token = slack_token
    end

    def start; end

    def stop; end
  end
end
