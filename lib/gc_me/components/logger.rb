require 'logger'
require 'fileutils'
require 'forwardable'

module GCMe
  module Components
    # Configures logging
    class Logger
      attr_reader :logger

      extend Forwardable
      def_delegators :logger, :debug, :info, :warn, :error, :fatal, :unknown

      def initialize(path)
        @path = path
      end

      def start
        FileUtils.mkdir_p(File.dirname(@path)) if @path

        @logger = ::Logger.new(@path || STDOUT).tap do |logger|
          logger.progname = 'gc-me'
        end
      end

      def stop
        # if we try to close the logger with $stdout it blows up...
        @logger&.close if @path

        @logger = nil
      end
    end
  end
end
