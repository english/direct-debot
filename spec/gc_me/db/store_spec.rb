require 'sequel'
require_relative '../../../lib/gc_me/db/store'

Sequel.extension(:migration)

RSpec.describe GCMe::DB::Store do
  let(:db) { Sequel.connect(Prius.get(:database_url)) }
  before { Sequel::Migrator.run(db, 'lib/gc_me/db/migrations') }
  subject(:store) { GCMe::DB::Store.new(db) }

  it 'persists Store records' do
    expect { store.create_slack_user!(gc_access_token: 'x', slack_user_id: 'y') }.
      to change { store.count_slack_users! }.
      by(1)
  end
end
