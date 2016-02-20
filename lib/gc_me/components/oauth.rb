# frozen_string_literal: true

require 'oauth2'

module GCMe
  module Components
    # Configures the oauth client
    class OAuth
      attr_reader :client

      def initialize(gc_client_id:, gc_client_secret:, gc_connect_url:,
                     gc_connect_authorize_path:, gc_connect_access_token_path:)
        @client            = nil
        @client_id         = gc_client_id
        @client_secret     = gc_client_secret
        @connect_url       = gc_connect_url
        @authorize_path    = gc_connect_authorize_path
        @access_token_path = gc_connect_access_token_path
      end

      def start
        connection_opts = { request: { timeout: 1 } }

        @client = OAuth2::Client.new(@client_id, @client_secret,
                                     site: @connect_url,
                                     authorize_url: @authorize_path,
                                     token_url: @access_token_path,
                                     connection_opts: connection_opts)
      end

      def stop
        @client = nil
      end
    end
  end
end
