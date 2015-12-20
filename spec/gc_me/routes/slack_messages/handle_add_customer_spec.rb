require_relative '../../../../lib/gc_me/routes/slack_messages/handle_add_customer'
require_relative '../../../../lib/gc_me/mail_client'

RSpec.describe GCMe::Routes::SlackMessages::HandleAddCustomer do
  subject(:handle_add_customer) do
    context = { request: double(params: params) }

    GCMe::Routes::SlackMessages::HandleAddCustomer.new(context, next_middleware,
                                                       mail_client: mail_client)
  end

  let(:mail_client) { instance_double(GCMe::MailClient::SMTP) }
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
      expect(mail_client).to(receive(:deliver!) do |message|
        from, to, subject, body = message.fetch_values(:from, :to, :subject, :body)

        expect(from).to eq('noreply@gc-me.test')
        expect(to).to eq('jane@example.com')
        expect(subject).to eq('Setup a direct debit with Joaquin')
        expect(body).to match(%r{Joaquin.+/add-customer\?user=US123})
      end)

      status, _headers, body = handle_add_customer.call

      expect(status).to eq(200)
      expect(body.first).to include('jane@example.com')
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
