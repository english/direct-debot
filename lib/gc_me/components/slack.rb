# frozen_string_literal: true

require 'uri'

module GCMe
  module Components
    # Reads messages from a queue and posts them to slack
    class Slack
      POST_MESSAGE_URL = URI('https://slack.com/api/chat.postMessage')

      attr_reader :input_queue, :slack_bot_api_token

      def initialize(slack_bot_api_token)
        @slack_bot_api_token = slack_bot_api_token
        @running             = false
        @logger              = nil
        @input_queue         = nil
      end

      def start(logger)
        @logger      = logger
        @input_queue = Queue.new

        thread = Thread.new do
          while message = @input_queue.deq
            post_form(POST_MESSAGE_URL, message.put(:token, slack_bot_api_token).to_h)
          end
        end

        thread.abort_on_exception = true
      end

      def stop
        @input_queue.close
      end

      private

      def post_form(uri, data)
        @logger.logger.info("sending slack message: #{data}")

        request = Net::HTTP::Post.new(uri)
        request.set_form_data(data)

        response = send_request(request, uri)

        @logger.logger.info(
          "response from sending slack message: #{response.code} #{response.message}")
      end

      def send_request(request, uri)
        Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          http.open_timeout = 1
          http.read_timeout = 1
          http.ssl_timeout  = 1

          http.request(request)
        end
      end
    end
  end
end
