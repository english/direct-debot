# frozen_string_literal: true

require_relative '../../../lib/gc_me/routes/gc_webhooks'
require_relative '../../../lib/gc_me/db/store'

RSpec.describe GCMe::Routes::GCWebhooks do
  subject(:gc_callback) do
    context = {
      request: double(
        params: params,
        body: StringIO.new(params.to_json),
        headers: { 'Webhook-Signature' => signature }
      )
    }

    described_class.new(context, nil, store: store, queue: queue, gc_webhook_secret: 'foo')
  end

  let(:params) do
    {
      'events' => [
        { 'id' => 'EV123', 'links' => { 'organisation' => 'OR123' } },
        { 'id' => 'EV456', 'links' => { 'organisation' => 'OR456' } }
      ]
    }
  end

  let(:store) { instance_double(GCMe::DB::Store) }
  let(:queue) { Queue.new }

  context 'when the signature matches' do
    let(:signature) { 'adeb7d7dca6adff480d83a0445f05d7bed919115059014e74842668415c67a2b' }

    it 'enqueues each event and organisation_id' do
      messages = []

      worker = Thread.new do
        while message = queue.pop
          messages << message
        end
      end

      worker.abort_on_exception = true

      expect(subject).to respond_with_status(204)

      expected_messages = [
        { organisation_id: 'OR123', event_id: 'EV123' },
        { organisation_id: 'OR456', event_id: 'EV456' }
      ]
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
