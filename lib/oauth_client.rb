require 'oauth2'
require 'prius'

# Builds an OAuth2::Client based off environment variables
module OauthClient
  def self.build
    client_id         = Prius.get(:gc_client_id)
    client_secret     = Prius.get(:gc_client_secret)
    connect_url       = Prius.get(:gc_connect_url)
    authorize_path    = Prius.get(:gc_connect_authorize_path)
    access_token_path = Prius.get(:gc_connect_access_token_path)

    OAuth2::Client.new(client_id, client_secret, site: connect_url,
                                                 authorize_url: authorize_path,
                                                 token_url: access_token_path)
  end
end
