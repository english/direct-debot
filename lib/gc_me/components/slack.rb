# frozen_string_literal: true

module GCMe
  module Components
    class Slack
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

            Net::HTTP.post_form(URI('https://slack.com/api/chat.postMessage'), message.to_h)

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
    end
  end
end
