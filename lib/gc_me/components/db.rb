# frozen_string_literal: true

require 'sequel'

module GCMe
  module Components
    # Manages connecting and disconnecting to the database at the given connection url
    class DB
      attr_reader :connection

      def initialize(url, connection = nil)
        @url = url
        @connection = connection
      end

      def start
        return self if @connection

        connection = Sequel.connect(@url)
        Sequel.extension(:migration)
        Sequel::Migrator.run(connection, 'lib/gc_me/db/migrations')

        self.class.new(@url, connection)
      end

      def stop
        return self unless @connection

        @connection&.disconnect

        self.class.new(@url)
      end
    end
  end
end
