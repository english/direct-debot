# frozen_string_literal: true

require 'coach'

module GCMe
  module Routes
    # Just so we know the app is up and running
    class Index < Coach::Middleware
      def call
        [200, {}, ['hello world!']]
      end
    end
  end
end
