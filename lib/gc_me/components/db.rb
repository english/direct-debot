# frozen_string_literal: true

require 'sequel'

module GCMe
  module Components
    # Manages connecting and disconnecting to the database at the given connection url
    class DB
      POOL_TIMEOUT    = 1
      CONNECT_TIMEOUT = 1

      attr_reader :database

      def initialize(url, max_connections = 1, database = nil)
        @url             = url
        @max_connections = max_connections
        @database        = database
      end

      def start
        return self if @database

        database = Sequel.connect(@url, max_connections: @max_connections,
                                        pool_timeout: POOL_TIMEOUT,
                                        connect_timeout: CONNECT_TIMEOUT,
                                        preconnect: true)
        Sequel.extension(:migration)
        Sequel::Migrator.run(database, 'lib/gc_me/db/migrations')

        self.class.new(@url, @max_connections, database)
      end

      def stop
        return self unless @database

        @database&.disconnect

        self.class.new(@url, @max_connections)
      end
    end
  end
end
