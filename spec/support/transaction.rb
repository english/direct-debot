# frozen_string_literal: true

require 'sequel'

module Transaction
  def self.with_rollback(system)
    system.fetch(:db_component).connection.transaction do
      begin
        yield
      ensure
        fail Sequel::Rollback
      end
    end
  end
end
