require 'prius'

Prius.load(:rack_env, type: :string)
Prius.load(:host, type: :string)
Prius.load(:database_url, type: :string)
Prius.load(:gc_client_id, type: :string)
Prius.load(:gc_client_secret, type: :string)
Prius.load(:gc_connect_url, type: :string)
Prius.load(:gc_connect_authorize_path, type: :string)
Prius.load(:gc_connect_access_token_path, type: :string)
Prius.load(:gc_environment, type: :string)
