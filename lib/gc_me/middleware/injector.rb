# frozen_string_literal: true

module GCMe
  module Middleware
    # Inject arbitrary values into the request env
    class Injector
      def initialize(app, config)
        @app = app
        @config = config
      end

      def call(env)
        env = @config.inject(env) { |h, (k, v)| h.merge("injected.#{k}" => v) }

        @app.call(env)
      end
    end
  end
end
