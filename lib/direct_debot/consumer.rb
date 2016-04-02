require 'airbrake'

module DirectDebot
  # Starts a consumer for a given queue, processing messages until the queue is closed.
  # Logs and rescues all exceptions.
  module Consumer
    def self.call(queue, logger, &block)
      Thread.new do
        while message = queue.deq
          log_progress(logger, message) { block.call(message) }
        end
      end
    end

    private_class_method def self.log_progress(logger, message, &block)
      logger.info("consuming message: #{message.inspect}")
      block.call
      logger.info("consumed message: #{message.inspect}")
    rescue => e
      logger.error("#{e.inspect}: #{e.message}\n#{e.backtrace}")
      Airbrake.notify(e)
    end
  end
end
