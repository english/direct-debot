# frozen_string_literal: true

require 'hamster'

module DirectDebot
  # Wraps OAuth2::Client with a nicer interface
  class OAuthClient
    def initialize(client, redirect_uri)
      @client = client
      @redirect_uri = redirect_uri
    end

    def create_access_token!(code)
      access_token = @client.auth_code.get_token(code, redirect_uri: @redirect_uri)

      Hamster::Hash.new(token: access_token.token,
                        organisation_id: access_token.params.fetch('organisation_id'))
    end

    def authorize_url(state)
      @client.auth_code.authorize_url(redirect_uri: @redirect_uri,
                                      state: state,
                                      scope: 'full_access',
                                      initial_view: 'login')
    end
  end
end
