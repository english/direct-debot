# frozen_string_literal: true

require 'sequel'

module Transaction
  def self.with_rollback(system)
    system.fetch(:db).database.execute('DELETE FROM redirect_flows;')
    system.fetch(:db).database.execute('DELETE FROM users;')

    yield

    # system.fetch(:db).database.transaction do
    #   begin
    #     yield
    #   ensure
    #     fail Sequel::Rollback
    #   end
    # end
  end
end
