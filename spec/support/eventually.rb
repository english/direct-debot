# frozen_string_literal: true

module Eventually
  def self.try(timeout:, sleep_time:)
    start_time = Time.now

    loop do
      begin
        break if yield
      rescue RSpec::Expectations::ExpectationNotMetError
        nil # keep Rubocop happy
      end

      fail Timeout::Eror if (Time.now - start_time) > (timeout * 1000)
      sleep(sleep_time)
    end
  end
end
