# frozen_string_literal: true

require 'mail'
require 'hamster'

module GCMe
  module Components
    # Wraps up the Mail library with a minimal interface.
    module Mail
      # Fake mail client
      class Test
        attr_reader :input_queue, :output_queue

        def initialize(input_queue, output_queue, _username, _password)
          @input_queue  = input_queue
          @output_queue = output_queue
          @running      = false
        end

        def start
          @running = true

          Thread.new do
            while @running
              message = @input_queue.pop
              @output_queue << message

              sleep(0.1)
            end
          end
        end

        def stop
          @running = false
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

        def initialize(input_queue, output_queue, user_name, password)
          @input_queue  = input_queue
          @output_queue = output_queue # Not used. Here to match api with test component
          @options      = DELIVERY_OPTIONS.merge(user_name: user_name, password: password)
          @running      = false
        end

        def start
          @running = true

          Thread.new do
            while @running
              mail = Mail::Message.new(@input_queue.pop.to_h)
              mail.delivery_method(:smtp, @options)
              mail.deliver!

              sleep(0.1)
            end
          end
        end

        def stop
          @running = false
        end
      end

      CLIENTS = Hamster::Hash.new(
        'test' => Test,
        'smtp' => SMTP
      )

      def self.build(delivery_method:, input_queue:, output_queue:, user_name:, password:)
        CLIENTS.fetch(delivery_method).new(input_queue, output_queue, user_name, password)
      end
    end
  end
end
