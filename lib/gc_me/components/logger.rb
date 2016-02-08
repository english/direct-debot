require 'logger'

module GCMe
  module Components
    # Configures logging
    class Logger
      attr_reader :logger

      def initialize(path)
        @path = path
      end

      def start
        @logger = ::Logger.new(@path || STDOUT).tap do |logger|
          logger.progname = 'gc-me'
        end

        self
      end

      def stop
        # if we try to close the logger with $stdout it blows up...
        @logger&.close if @path

        @logger = nil

        self
      end
    end
  end
end
