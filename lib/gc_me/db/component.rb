# frozen_string_literal: true

require 'sequel'

module GCMe
  module DB
    # Manages connecting and disconnecting to the database at the given connection url
    class Component
      attr_reader :connection

      def initialize(url)
        @url = url
        @connection = nil
      end

      def start
        @connection = Sequel.connect(@url)
        Sequel.extension(:migration)
        Sequel::Migrator.run(@connection, 'lib/gc_me/db/migrations')
      end

      def stop
        @connection&.disconnect
      end
    end
  end
end
