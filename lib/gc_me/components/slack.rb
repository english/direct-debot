# frozen_string_literal: true

require 'uri'

module GCMe
  module Components
    class Slack
      POST_MESSAGE_URL = URI('https://slack.com/api/chat.postMessage')

      attr_reader :input_queue, :slack_bot_api_token

      def initialize(input_queue, slack_bot_api_token)
        @input_queue = input_queue
        @slack_bot_api_token = slack_bot_api_token
        @running = false
      end

      def start
        return self if @running

        @running = true

        thread = Thread.new do
          while @running
            message = @input_queue.pop
            message = message.put(:token, slack_bot_api_token)

            post_form(POST_MESSAGE_URL, message.to_h)

            sleep(0.1)
          end
        end

        thread.abort_on_exception = true

        self
      end

      def stop
        @running = false

        self
      end

      private

      def post_form(uri, data)
        request = Net::HTTP::Post.new(uri)
        request.set_form_data(data)

        Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          http.open_timeout = 1
          http.read_timeout = 1
          http.ssl_timeout = 1

          http.request(request)
        end
      end
    end
  end
end
