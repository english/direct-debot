require 'json_schema'
require 'gocardless_pro'
require_relative '../../../lib/gc_me/oauth_client'
require_relative '../../../lib/gc_me/gc_client'
require_relative '../../../lib/gc_me/mail_client'
require_relative '../../../lib/gc_me/db/store'
require_relative '../../../lib/gc_me/routes/slack_messages'

RSpec::Matchers.define :validate do |data|
  match { |schema| schema.validate(data).first }
end

RSpec.describe GCMe::Routes::SlackMessages::SCHEMA do
  let(:valid_params) do
    {
      'token'        => 'gIkuvaNzQIHg97ATvDxqgjtO',
      'team_id'      => 'T0001',
      'team_domain'  => 'example',
      'channel_id'   => 'C2147483705',
      'channel_name' => 'test',
      'user_id'      => 'U2147483697',
      'user_name'    => 'Steve',
      'command'      => '/gc-me',
      'text'         => '£10 from @jane'
    }
  end

  let(:schema) { JsonSchema.parse!(GCMe::Routes::SlackMessages::SCHEMA) }

  it 'knows what valid params are' do
    expect(schema).to validate(valid_params)
  end

  it "validates 'authorise' messages" do
    expect(schema).to validate(valid_params.merge('text' => 'authorise'))
    expect(schema).to_not validate(valid_params.merge('text' => 'authorize'))
  end

  it "validates 'payment' messages" do
    valid_amounts      = ['10', '0.1', '1.50']
    valid_currencies   = ['€', '£']
    invalid_currencies = ['', 'a', '$']

    valid_currencies.product(valid_amounts).each do |(currency, amount)|
      data = valid_params.merge('text' => "#{currency}#{amount} from someone")

      expect(schema).to validate(data)
    end

    invalid_currencies.product(valid_amounts).each do |(currency, amount)|
      data = valid_params.merge('text' => "#{currency}#{amount} from someone")

      expect(schema).to_not validate(data)
    end
  end

  it "validates 'add customer' messages" do
    expect(schema).to validate(valid_params.merge('text' => 'add foo@bar.com'))

    expect(schema).to_not validate(valid_params.merge('text' => 'add foo'))
    expect(schema).to_not validate(valid_params.merge('text' => 'add @jane'))
  end
end

RSpec.describe GCMe::Routes::HandleAddCustomer do
  subject(:handle_add_customer) do
    context = { request: double(params: params) }

    GCMe::Routes::HandleAddCustomer.new(context, next_middleware,
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
        expect(body).to match(%r{Joaquin.+/authorise/US123})
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

RSpec.describe GCMe::Routes::HandleAuthorize do
  subject(:handle_authorize) do
    context = { request: double(params: params) }

    GCMe::Routes::HandleAuthorize.new(context, next_middleware,
                                      oauth_client: oauth_client)
  end

  let(:oauth_client) { instance_double(GCMe::OAuthClient) }
  let(:next_middleware) { -> () {} }

  context 'when given an authorise message' do
    let(:params) { { 'user_id' => 'slack-user-id', 'text' => 'authorise' } }

    it 'returns a gc oauth link' do
      expect(oauth_client).
        to receive(:authorise_url).
        with('slack-user-id').
        and_return('https://authorise-url')

      status, _headers, body = handle_authorize.call

      expect(status).to eq(200)
      expect(body.first).to eq('<https://authorise-url|Click me!>')
    end
  end

  context 'when not given an authorise message' do
    let(:params) { { 'user_id' => 'slack-user-id', 'text' => 'bla' } }

    it 'calls the next middleware' do
      expect(next_middleware).to receive(:call)
      handle_authorize.call
    end
  end
end

RSpec.describe GCMe::Routes::HandlePayment do
  it 'creates a payment' do
    gc_client       = instance_double(GCMe::GCClient)
    payment_message = double(currency: 'GBP', pence: 1)
    gc_mandate      = double

    slack_messages = GCMe::Routes::HandlePayment.new(gc_client: gc_client,
                                                     payment_message: payment_message,
                                                     gc_mandate: gc_mandate)

    expect(gc_client).
      to receive(:create_payment).
      with(gc_mandate, 'GBP', 1)

    status, * = slack_messages.call

    expect(status).to eq(200)
  end
end
