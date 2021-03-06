# frozen_string_literal: true

require_relative '../../../lib/direct_debot/system'
require_relative '../../../lib/direct_debot/db/store'
require_relative '../../support/transaction'

RSpec.describe DirectDebot::DB::Store do
  let(:system) { DirectDebot::System.build }

  around do |example|
    system.start
    example.call
    system.stop
  end

  subject(:store) { described_class.new(system.fetch(:db).database) }

  it 'persists user records' do
    properties = property_of {
      dict(3) { [choose(:gc_access_token, :slack_user_id, :organisation_id), string] }
    }

    properties.check do |user|
      Transaction.with_rollback(system) do
        expect { store.create_user!(user) }.
          to change { store.count_users! }.
          by(1)

        expect(store.all_users.last.to_h).to be > user
      end
    end
  end

  context 'when a slack user already exists' do
    it 'overwrites the existing row' do
      properties = property_of { [array(range(1, 10)) { string }, string, string] }

      properties.check do |(access_tokens, organisation_id, user_id)|
        Transaction.with_rollback(system) do
          expect {
            access_tokens.each do |token|
              store.create_user!(gc_access_token: token, organisation_id: organisation_id,
                                 slack_user_id: user_id)
            end
          }.to change { store.all_users.count }.by(1)

          user = store.find_user(user_id)
          expect(user.fetch(:gc_access_token)).to eq(access_tokens.last)
        end
      end
    end
  end

  it 'finds a gc access token by a gc redirect flow id' do
    properties = property_of { [string, string, string, string] }

    properties.check do |(token, user_id, organisation_id, redirect_flow_id)|
      Transaction.with_rollback(system) do
        store.create_user!(gc_access_token: token, organisation_id: organisation_id,
                           slack_user_id: user_id)
        store.create_redirect_flow!(user_id, redirect_flow_id)

        redirect_flow = store.find_redirect_flow(redirect_flow_id)
        access_token = store.find_access_token_for_redirect_flow(redirect_flow.fetch(:id))

        expect(access_token).to eq(token)
      end
    end
  end
end
