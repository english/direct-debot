# frozen_string_literal: true

require 'coach'

module GCMe
  module Middleware
    # Fetches the gc_access_token from the stored slack user.
    # If the slack user is not already authorised (in the store) then an error response is
    # returned.
    class GetGCAccessToken < Coach::Middleware
      provides :gc_access_token

      def call
        store         = config.fetch(:store)
        slack_user_id = params.fetch('user_id')

        slack_user = store.find_user(slack_user_id)

        if slack_user
          gc_access_token = slack_user.fetch(:gc_access_token)

          provide(gc_access_token: gc_access_token)

          next_middleware.call
        else
          [200, {}, ['You need to authorise first!']]
        end
      end
    end
  end
end
