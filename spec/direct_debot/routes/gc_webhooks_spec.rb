# frozen_string_literal: true

require_relative '../../../lib/direct_debot/routes/gc_webhooks'
require_relative '../../../lib/direct_debot/db/store'

RSpec.describe DirectDebot::Routes::GCWebhooks do
  subject(:gc_callback) do
    context = {
      request: double(
        params: params,
        body: StringIO.new(params.to_json),
        headers: { 'Webhook-Signature' => signature }
      )
    }

    described_class.new(context, nil,
                        store: store, queue: queue, gc_webhook_secret: 'foo')
  end

  let(:params) do
    {
      'events' => [
        { 'id' => 'EV123', 'links' => { 'organisation' => 'OR123' } },
        { 'id' => 'EV456', 'links' => { 'organisation' => 'OR456' } }
      ]
    }
  end

  let(:store) { instance_double(DirectDebot::DB::Store) }
  let(:queue) { Queue.new }

  context 'when the signature matches' do
    let(:signature) { 'adeb7d7dca6adff480d83a0445f05d7bed919115059014e74842668415c67a2b' }

    it 'enqueues each event and organisation_id' do
      expect(subject).to respond_with_status(204)

      expected_messages = [
        { organisation_id: 'OR123', event_id: 'EV123' },
        { organisation_id: 'OR456', event_id: 'EV456' }
      ]
      messages = queue.size.times.map { queue.pop }

      expect(messages).to match_array(expected_messages)
    end
  end

  context "when the signature doesn't match" do
    let(:signature) { 'wrong' }

    it 'returns a 498' do
      expect(subject).to respond_with_status(498)
      expect(queue).to be_empty
    end
  end
end
