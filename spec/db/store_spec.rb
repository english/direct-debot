require 'sequel'
require_relative '../../db/store'

Sequel.extension(:migration)

RSpec.describe DB::Store do
  let(:db) { Sequel.connect(Prius.get(:database_url)) }
  before { Sequel::Migrator.run(db, 'db/migrations') }
  subject(:store) { DB::Store.new(db) }

  it 'persists Store records' do
    expect { store.create_slack_user!(gc_access_token: 'x', slack_user_id: 'y') }.
      to change { store.count_slack_users! }.
      by(1)
  end
end
