# frozen_string_literal: true

module GCMe
  module Components
    # Poorly named, but holds configuration for 'server'y stuff. And a slack token...
    class Server
      attr_reader :host, :environment, :slack_token, :slack_bot_api_token

      def initialize(host, environment, slack_token, slack_bot_api_token)
        @host = URI.parse(host)
        @environment = environment.to_sym
        @slack_token = slack_token
        @slack_bot_api_token = slack_bot_api_token
      end

      def start
        self
      end

      def stop
        self
      end
    end
  end
end
