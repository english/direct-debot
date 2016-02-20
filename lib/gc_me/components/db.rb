# frozen_string_literal: true

require 'sequel'

module GCMe
  module Components
    # Manages connecting and disconnecting to the database at the given connection url
    class DB
      POOL_TIMEOUT    = 1
      CONNECT_TIMEOUT = 2

      attr_reader :database

      def initialize(url, max_connections = 1)
        @url             = url
        @max_connections = max_connections
        @database        = database
      end

      def start
        return self if @database

        @database = Sequel.connect(@url, max_connections: @max_connections,
                                         pool_timeout: POOL_TIMEOUT,
                                         connect_timeout: CONNECT_TIMEOUT,
                                         preconnect: true)
        Sequel.extension(:migration)
        Sequel::Migrator.run(database, 'lib/gc_me/db/migrations')
      end

      def stop
        # sqlite doesn't like to be disconnected for some reason...
        @database&.disconnect unless sqlite?

        @database = nil
      end

      private

      def sqlite?
        defined?(Sequel::SQLite::Database) && @database.is_a?(Sequel::SQLite::Database)
      end
    end
  end
end
