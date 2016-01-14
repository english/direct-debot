# frozen_string_literal: true

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
Prius.load(:slack_token, type: :string)
Prius.load(:mail_delivery_method, type: :string)
Prius.load(:sendgrid_username, type: :string)
Prius.load(:sendgrid_password, type: :string)
Prius.load(:thread_count, type: :int)
