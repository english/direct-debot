require_relative '../../../lib/gc_me/db/store'

RSpec.describe GCMe::DB::Store do
  subject(:store) { GCMe::DB::Store.new(@db) }

  it 'persists user records' do
    user = { gc_access_token: 'x', slack_user_id: 'y' }

    expect { store.create_user!(user) }.
      to change { store.count_users! }.
      by(1)

    expect(store.all_users.last).to be > user
  end

  context 'when a slack user already exists' do
    it 'overwrites the existing row' do
      store.create_user!(gc_access_token: 'abc', slack_user_id: 'USER')
      store.create_user!(gc_access_token: 'xyz', slack_user_id: 'USER')

      users = store.all_users.
        select { |user| user.fetch(:slack_user_id) == 'USER' }

      expect(users.count).to eq(1)
      expect(users.last.fetch(:gc_access_token)).to eq('xyz')
    end
  end

  it "finds a gc access token by a gc redirect flow id" do
    store.create_user!(gc_access_token: 'abc', slack_user_id: 'USER')
    store.create_redirect_flow!('USER', 'RF123')

    access_token = store.find_access_token_for_redirect_flow('RF123')

    expect(access_token).to eq('abc')
  end
end
