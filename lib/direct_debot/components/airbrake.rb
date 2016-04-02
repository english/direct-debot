require 'airbrake'

module DirectDebot
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
        return if self.class.configured

        ::Airbrake.configure do |config|
          config.project_id = @id
          config.project_key = @key
        end

        self.class.configured = true
      end

      def stop
        # noop since attempting to configure again will raise an exception
      end
    end
  end
end
