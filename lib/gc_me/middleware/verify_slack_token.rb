# frozen_string_literal: true

require 'coach'

module GCMe
  module Middleware
    # Slack will send a `token` along with each request.
    # We can use this to verify that requests have actually came from Slack.
    class VerifySlackToken < Coach::Middleware
      def call
        expected_token = config.fetch(:slack_token)
        given_token    = params.fetch(:token)

        if expected_token == given_token
          next_middleware.call
        else
          [200, {}, ['Bad token!']]
        end
      end
    end
  end
end
