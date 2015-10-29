require 'coach'
require 'json'

module Routes
  # Handles Slack messages in the format of
  #   /gc-me <amount> from <user>
  # or
  #   /gc-me authorise
  class GCCallback < Coach::Middleware
    def call
      [200, {}, [request.params.to_h.to_json]]
    end
  end
end
