# frozen_string_literal: true

require 'uri'
require_relative '../consumer'

module GCMe
  module Components
    # Reads messages from a queue and posts them to slack
    class Slack
      attr_reader :input_queue, :slack_bot_api_token

      def initialize(slack_bot_api_token, slack_message_url)
        @slack_bot_api_token = slack_bot_api_token
        @slack_message_url   = URI(slack_message_url)
        @input_queue         = nil
      end

      def start(logger)
        @input_queue = SizedQueue.new(5)
        @thread = Consumer.call(@input_queue, logger) { |message|
          process_message(message)
        }
      end

      def stop
        @input_queue.close
        @thread.join
      end

      private

      def process_message(message)
        HTTP.post(@slack_message_url, message.put(:token, slack_bot_api_token).to_h)
      end

      # HTTP interface
      module HTTP
        def self.post(uri, data)
          request = Net::HTTP::Post.new(uri)
          request.set_form_data(data)

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
end
