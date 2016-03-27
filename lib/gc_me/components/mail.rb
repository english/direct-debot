# frozen_string_literal: true

require 'mail'
require 'hamster'
require_relative '../consumer'

module GCMe
  module Components
    # Wraps up the Mail library with a minimal interface.
    module Mail
      # Fake mail client
      class Test
        attr_reader :input_queue, :output_queue

        def initialize(_username, _password)
          @input_queue  = nil
          @output_queue = nil
        end

        def start(logger)
          @input_queue  = SizedQueue.new(5)
          @output_queue = SizedQueue.new(5)

          @thread = Consumer.call(@input_queue, logger) { |message|
            @output_queue << message
          }
        end

        def stop
          @input_queue.close
          @output_queue.close
          @thread.join
        end
      end

      # Real mail client
      class SMTP
        DELIVERY_OPTIONS = {
          address: 'smtp.sendgrid.net',
          port: '587',
          domain: 'heroku.com',
          authentication: :plain,
          enable_starttls_auto: true
        }

        attr_reader :input_queue, :output_queue

        def initialize(user_name, password)
          @options      = DELIVERY_OPTIONS.merge(user_name: user_name, password: password)
          @input_queue  = nil
          @output_queue = nil
        end

        def start(logger)
          @input_queue  = SizedQueue.new(5)
          @output_queue = SizedQueue.new(5)

          @thread = Consumer.call(@input_queue, logger) { |message|
            mail = ::Mail::Message.new(message.to_h)
            mail.delivery_method(:smtp, @options)

            mail.deliver!
          }
        end

        def stop
          @input_queue.close
          @output_queue.close
          @thread.join
        end
      end

      CLIENTS = Hamster::Hash.new(
        'test' => Test,
        'smtp' => SMTP
      )

      def self.build(delivery_method:, user_name:, password:)
        CLIENTS.fetch(delivery_method).new(user_name, password)
      end
    end
  end
end
