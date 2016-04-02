# frozen_string_literal: true

require 'json_schema'
require 'coach'

module DirectDebot
  module Middleware
    # validate request against a given json schema
    class JSONSchema < Coach::Middleware
      def call
        schema = JsonSchema.parse!(config.fetch(:schema))
        valid, errors = schema.validate(params)

        if valid
          next_middleware.call
        else
          body = serialise_errors(errors)

          [400, {}, [body]]
        end
      end

      private

      def serialise_errors(errors)
        errors.
          map { |error| "error: #{error.type}\nmessage: #{error.message}" }.
          join("\n\n")
      end
    end
  end
end
