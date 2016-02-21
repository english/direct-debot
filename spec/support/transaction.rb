# frozen_string_literal: true

module Transaction
  def self.with_rollback(system)
    db = system.fetch(:db).database

    db.execute('DELETE FROM redirect_flows;')
    db.execute('DELETE FROM users;')

    yield
  end
end
