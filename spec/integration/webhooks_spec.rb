# frozen_string_literal: true

require 'webmock/rspec'
require_relative '../support/transaction'
require_relative '../support/eventually'
require_relative '../../lib/gc_me'
require_relative '../../lib/gc_me/db/store'
require_relative '../../lib/gc_me/system'

RSpec.describe 'processing webhooks' do
  let(:system) { GCMe::System.build }

  around do |example|
    system.start
    Transaction.with_rollback(system) { example.call }
    system.stop
  end

  subject(:app) { Rack::MockRequest.new(GCMe::Application.new(system).rack_app) }

  let(:webhook_headers) do
    {
      'HTTP_USER_AGENT' => 'gocardless-webhook-service/1.1',
      'HTTP_CONTENT_TYPE' => 'application/json',
      'HTTP_WEBHOOK_SIGNATURE' =>
        'b02b11f82140eded07369dc8cfafb587bfd951ce7394a906df8eaa50d4c39afb'
    }
  end

  let(:ev123) do
    {
      'id' => 'EV123',
      'created_at' => '2014-08-03T12:00:00.000Z',
      'action' => 'confirmed',
      'resource_type' => 'payments',
      'links' => {
        'payment' => 'PM123',
        'organisation' => 'OR123'
      },
      'details' => {
        'origin' => 'gocardless',
        'cause' => 'payment_confirmed',
        'description' => 'Payment was confirmed as collected'
      }
    }
  end

  let(:ev456) do
    {
      'id' => 'EV456',
      'created_at' => '2014-08-03T12:00:00.000Z',
      'action' => 'failed',
      'resource_type' => 'payments',
      'links' => {
        'payment' => 'PM456',
        'organisation' => 'OR456'
      },
      'details' => {
        'origin' => 'bank',
        'cause' => 'mandate_cancelled',
        'description' => 'Customer cancelled the mandate at their bank branch.',
        'scheme' => 'bacs',
        'reason_code' => 'ARUDD-1'
      }
    }
  end

  let!(:ev123_request) do
    stub_request(:get, 'https://api-sandbox.gocardless.com/events/EV123').
      to_return(status: 200, body: { events: ev123 }.to_json,
                headers: { 'Content-Type' => 'application/json' })
  end

  let!(:ev456_request) do
    stub_request(:get, 'https://api-sandbox.gocardless.com/events/EV456').
      to_return(status: 200, body: { events: ev456 }.to_json,
                headers: { 'Content-Type' => 'application/json' })
  end

  let!(:ev123_message) do
    params = {
      channel: 'US123',
      token: system.fetch(:slack_component).slack_bot_api_token,
      as_user: 'true',
      text: 'Payment PM123 confirmed'
    }

    stub_request(:post, 'https://slack.com/api/chat.postMessage').
      with(body: params).
      to_return(status: 200, body: { events: ev123 }.to_json,
                headers: { 'Content-Type' => 'application/json' })
  end

  let!(:ev456_message) do
    params = {
      channel: 'US456',
      token: system.fetch(:slack_component).slack_bot_api_token,
      as_user: 'true',
      text: 'Payment PM456 failed'
    }

    stub_request(:post, 'https://slack.com/api/chat.postMessage').
      with(body: params).
      to_return(status: 200, body: { events: ev456 }.to_json,
                headers: { 'Content-Type' => 'application/json' })
  end

  let(:params) { { 'events' => [ev123, ev456] } }

  before do
    store = GCMe::DB::Store.new(system.fetch(:db_component).database)

    store.create_user!(slack_user_id: 'US123',
                       organisation_id: 'OR123',
                       gc_access_token: 'AT123')

    store.create_user!(slack_user_id: 'US456',
                       organisation_id: 'OR456',
                       gc_access_token: 'AT456')
  end

  it 'records receipt of the webhook and notifies the slack user' do
    host = system.fetch(:server_component).host.to_s

    response = app.post("#{host}/api/gc/webhooks", webhook_headers.merge(params: params))

    expect(response.status).to eq(204)

    Eventually.try(timeout: 1, sleep_time: 0.1) do
      expect(ev123_request).to have_been_made
      expect(ev456_request).to have_been_made

      expect(ev123_message).to have_been_made
      expect(ev456_message).to have_been_made
    end
  end
end
