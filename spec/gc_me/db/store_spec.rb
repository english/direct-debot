require 'sequel'
require_relative '../../../lib/gc_me/db/store'

Sequel.extension(:migration)

RSpec.describe GCMe::DB::Store do
  let(:db) { Sequel.connect(Prius.get(:database_url)) }
  before { Sequel::Migrator.run(db, 'lib/gc_me/db/migrations') }
  subject(:store) { GCMe::DB::Store.new(db) }

  it 'persists slack_user records' do
    slack_user = { gc_access_token: 'x', slack_user_id: 'y' }

    expect { store.create_slack_user!(slack_user) }.
      to change { store.count_slack_users! }.
      by(1)

    expect(store.all_slack_users.last).to eq(slack_user)
  end

  context 'when a slack user already exists' do
    it 'overwrites the existing row' do
      store.create_slack_user!(gc_access_token: 'abc', slack_user_id: 'USER')
      store.create_slack_user!(gc_access_token: 'xyz', slack_user_id: 'USER')

      expect(store.all_slack_users.last.fetch(:gc_access_token)).to eq('xyz')
    end
  end
end
