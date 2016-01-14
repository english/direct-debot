require 'airbrake'

module GCMe
  module Components
    # Configures Airbrake exception monitoring
    class Airbrake
      class << self
        attr_accessor :configured
      end

      def initialize(id, key)
        @id  = id
        @key = key
      end

      def start
        return self if self.class.configured

        ::Airbrake.configure do |config|
          config.project_id = @id
          config.project_key = @key
        end

        self.class.configured = true

        self
      end

      def stop
        # noop since attempting to configure again will raise an exception

        self
      end
    end
  end
end
