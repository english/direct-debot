# frozen_string_literal: true

require_relative '../../../lib/direct_debot/middleware/get_gc_access_token'
require_relative '../../../lib/direct_debot/db/store'

RSpec.describe DirectDebot::Middleware::GetGCAccessToken do
  subject(:route) { described_class.new(context, next_middleware, store: store) }

  let(:store) { instance_double(DirectDebot::DB::Store) }
  let(:next_middleware) { null_middleware }

  context 'when the slack user exists' do
    let(:context) do
      { request: double(params: { 'user_id' => 'slack-user-id' }) }
    end

    before do
      expect(store).
        to receive(:find_user).
        with('slack-user-id').
        and_return(gc_access_token: 'gc-access-token')
    end

    it { is_expected.to call_next_middleware }
    it { is_expected.to provide(gc_access_token: 'gc-access-token') }
  end

  context 'when the slack user does not exist' do
    let(:context) do
      { request: double(params: { 'user_id' => 'slack-user-id' }) }
    end

    before do
      expect(store).
        to receive(:find_user).
        with('slack-user-id').
        and_return(nil)
    end

    it { is_expected.to_not call_next_middleware }
    it { is_expected.to respond_with_body_that_matches('authorise') }
  end
end
