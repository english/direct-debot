require 'coach'
require_relative 'store_provider'

module GCMe
  module Middleware
    class GetGCAccessToken < Coach::Middleware
      uses Middleware::StoreProvider

      requires :store

      provides :gc_access_token

      def call
        slack_user_id = params.fetch('user_id')
        slack_user    = store.find_slack_user(slack_user_id)

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
