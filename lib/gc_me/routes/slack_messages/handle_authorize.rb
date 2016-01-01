# frozen_string_literal: true

require 'coach'

module GCMe
  module Routes
    # Groups handlers for slack messages
    module SlackMessages
      # If the message is 'authorise'
      class HandleAuthorize < Coach::Middleware
        def call
          oauth_client = config.fetch(:oauth_client)
          user_id = params.fetch('user_id')

          url  = oauth_client.authorize_url(user_id)
          body = SlackLink.new(url, 'Click me!').to_s

          [200, {}, [body]]
        end
      end

      SlackLink = Struct.new(:url, :label) do
        def to_s
          "<#{url}|#{label}>"
        end
      end
    end
  end
end
