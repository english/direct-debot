require_relative '../../../lib/gc_me/db/store'

RSpec.describe GCMe::DB::Store do
  subject(:store) { GCMe::DB::Store.new(@db) }

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

      slack_users = store.all_slack_users.
        select { |slack_user| slack_user.fetch(:slack_user_id) == 'USER' }

      expect(slack_users.count).to eq(1)
      expect(slack_users.last.fetch(:gc_access_token)).to eq('xyz')
    end
  end
end
