require 'active_support/concern'
require 'action_dispatch/http/request'
require_relative '../../../lib/gc_me/middleware/get_gc_access_token'
require_relative '../../../lib/gc_me/db/store'

RSpec.describe GCMe::Middleware::GetGCAccessToken do
  context 'when the slack user exists' do
    it 'provides the slack user from the store' do
      store           = instance_double(GCMe::DB::Store)
      next_middleware = double
      request         = instance_double(ActionDispatch::Request,
                                        params: { 'user_id' => 'slack-user-id' })

      context = { store: store, request: request }

      subject = GCMe::Middleware::GetGCAccessToken.new(context, next_middleware)

      expect(store).
        to receive(:find_slack_user).
        with('slack-user-id').
        and_return(gc_access_token: 'gc-access-token')

      expect(next_middleware).to receive(:call)

      expect(subject).
        to receive(:provide).
        with(gc_access_token: 'gc-access-token')

      subject.call
    end
  end

  context 'when the slack user does not exist' do
    it 'responds with an error message' do
      store           = instance_double(GCMe::DB::Store)
      next_middleware = double
      request         = instance_double(ActionDispatch::Request,
                                        params: { 'user_id' => 'slack-user-id' })

      context = { store: store, request: request }

      subject = GCMe::Middleware::GetGCAccessToken.new(context, next_middleware)

      expect(store).
        to receive(:find_slack_user).
        with('slack-user-id').
        and_return(nil)

      expect(next_middleware).to_not receive(:call)

      _status, _headers, body = subject.call

      expect(body.first).to include('authorise')
    end
  end
end
