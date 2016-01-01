# frozen_string_literal: true

require_relative '../../../../lib/gc_me/routes/slack_messages/handle_add_customer'

RSpec.describe GCMe::Routes::SlackMessages::HandleAddCustomer do
  subject(:handle_add_customer) do
    context = { request: double(params: params) }

    described_class.new(context, null_middleware, mail_queue: mail_queue,
                                                  host: 'http://gc-me.test')
  end

  let(:mail_queue) { Queue.new }

  context "when given an 'add customer' message" do
    let(:params) do
      {
        'text'      => 'customers add jane@example.com',
        'user_name' => 'Joaquin',
        'user_id'   => 'US123'
      }
    end

    it { is_expected.to respond_with_status(200) }
    it { is_expected.to respond_with_body_that_matches('jane@example.com') }

    it 'adds a message to the mail queue' do
      handle_add_customer.call

      expect(mail_queue.length).to eq(1)
      message = mail_queue.pop

      from, to, subject, body = message.fetch_values(:from, :to, :subject, :body)

      expect(from).to eq('noreply@gc-me.test')
      expect(to).to eq('jane@example.com')
      expect(subject).to eq('Setup a direct debit with Joaquin')
      expect(body).to match(%r{Joaquin.+/add-customer\?user_id=US123})
    end
  end
end
