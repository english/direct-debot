# frozen_string_literal: true

require 'oauth2'

module GCMe
  # Wraps OAuth2::Client with a nicer interface
  class OAuthClient
    def initialize(env, redirect_uri)
      @redirect_uri = redirect_uri
      @client = build_oauth_client(env)
    end

    def create_access_token!(code)
      @client.auth_code.get_token(code, redirect_uri: @redirect_uri).token
    end

    def authorize_url(state)
      @client.auth_code.authorize_url(redirect_uri: @redirect_uri,
                                      state: state,
                                      scope: 'full_access',
                                      initial_view: 'login')
    end

    private

    def build_oauth_client(env)
      client_id         = env.get(:gc_client_id)
      client_secret     = env.get(:gc_client_secret)
      connect_url       = env.get(:gc_connect_url)
      authorize_path    = env.get(:gc_connect_authorize_path)
      access_token_path = env.get(:gc_connect_access_token_path)

      OAuth2::Client.new(client_id, client_secret, site: connect_url,
                                                   authorize_url: authorize_path,
                                                   token_url: access_token_path)
    end
  end
end
