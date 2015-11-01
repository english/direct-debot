require 'json_schema'
require 'coach'

module GCMe
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
        errors.map do |error|
          "error: #{error.type}\n" \
          "message: #{error.message}"
        end

        errors.join("\n\n")
      end
    end
  end
end
