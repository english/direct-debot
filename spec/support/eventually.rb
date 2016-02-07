# frozen_string_literal: true

module Eventually
  def self.try(timeout:, sleep_time:)
    raise ArgumentError, 'block required' unless block_given?

    start_time = Time.now

    loop do
      result = yield
      break if result

      raise Timeout::Eror if (Time.now - start_time) > timeout
      sleep(sleep_time)
    end
  end
end
