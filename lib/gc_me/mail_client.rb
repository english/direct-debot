require 'mail'

module GCMe
  # Wraps up the Mail library with a minimal interface.
  module MailClient
    def self.build(delivery_method, user_name, password)
      clients = {
        'test' => Test,
        'smtp' => SMTP
      }

      clients.fetch(delivery_method).new(user_name, password)
    end

    # Fake mail client
    class Test
      @deliveries = []

      class << self
        attr_reader :deliveries
      end

      def self.clear!
        @deliveries = []
      end

      def self.add_delivery(message)
        @deliveries << message
      end

      def initialize(*)
      end

      def deliver!(message_hash)
        self.class.add_delivery(message_hash)
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

      def initialize(user_name, password)
        @options = DELIVERY_OPTIONS.merge(user_name: user_name, password: password)
      end

      def deliver!(message_hash)
        message = Mail::Message.new(message_hash)
        message.delivery_method(:smtp, @options)

        message.deliver!
      end
    end
  end
end
