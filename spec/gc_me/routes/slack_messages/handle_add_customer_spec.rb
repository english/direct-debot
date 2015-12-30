# frozen_string_literal: true

require_relative '../../../../lib/gc_me/routes/slack_messages/handle_add_customer'

RSpec.describe GCMe::Routes::SlackMessages::HandleAddCustomer do
  subject(:handle_add_customer) do
    context = { request: double(params: params) }

    described_class.new(context, next_middleware, mail_queue: mail_queue,
                                                  host: 'http://gc-me.test')
  end

  let(:mail_queue) { Queue.new }
  let(:next_middleware) { -> () {} }

  context "when given an 'add customer' message" do
    let(:params) do
      {
        'text'      => 'add jane@example.com',
        'user_name' => 'Joaquin',
        'user_id'   => 'US123'
      }
    end

    it 'returns a success message' do
      status, _headers, body = handle_add_customer.call

      expect(status).to eq(200)
      expect(body.first).to include('jane@example.com')

      expect(mail_queue.length).to eq(1)
      message = mail_queue.pop

      from, to, subject, body = message.fetch_values(:from, :to, :subject, :body)

      expect(from).to eq('noreply@gc-me.test')
      expect(to).to eq('jane@example.com')
      expect(subject).to eq('Setup a direct debit with Joaquin')
      expect(body).to match(%r{Joaquin.+/add-customer\?user_id=US123})
    end
  end

  context "when not given an 'add customer' message" do
    let(:params) do
      {
        'text'      => 'bla bla',
        'user_name' => 'Joaquin',
        'user_id'   => 'US123'
      }
    end

    it 'calls the next middleware' do
      expect(next_middleware).to receive(:call)
      handle_add_customer.call
    end
  end
end
