require 'active_support/concern'
require 'action_dispatch/http/request'
require 'json_schema'
require 'gocardless_pro'
require_relative '../../../lib/gc_me/oauth_client'
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
end

RSpec.describe GCMe::Routes::SlackMessages do
  subject(:slack_messages) { GCMe::Routes::SlackMessages.new(context) }

  let(:context) do
    {
      request: instance_double(ActionDispatch::Request, params: params),
      store: store,
      oauth_client: oauth_client
    }
  end

  let(:oauth_client) { instance_double(GCMe::OAuthClient) }
  let(:store) { instance_double(GCMe::DB::Store) }

  describe 'given an authorise message' do
    let(:params) { { 'user_id' => 'slack-user-id', 'text' => 'authorise' } }

    it 'returns a gc oauth link' do
      expect(oauth_client).
        to receive(:authorise_url).
        with('slack-user-id').
        and_return('https://authorise-url')

      status, _headers, body = slack_messages.call

      expect(status).to eq(200)
      expect(body.first).to eq('<https://authorise-url|Click me!>')
    end
  end

  describe 'given a payment message' do
    let(:params) do
      { 'user_id' => 'slack-user-id', 'text' => '£10 from someone@example.com' }
    end

    context "when the user hasn't already authorised" do
      before do
        expect(store).
          to receive(:find_slack_user).
          with('slack-user-id').
          and_return(nil)
      end

      it 'sends an error message' do
        status, _headers, body = slack_messages.call

        expect(body.first).to eq('You need to authorise first!')
      end
    end

    context 'when the access token has been disabled'

    context 'with a recipient that exists' do
      context 'and has an active mandate' do
        it 'creates a gc payment against that customer' do
          expect(store).
            to receive(:find_slack_user).
            with('slack-user-id').
            and_return(slack_user_id: 'slack-user-id', gc_access_token: 'access-token')

          gc_client = instance_double(GoCardlessPro::Client)

          expect(GoCardlessPro::Client).
            to receive(:new).
            with(access_token: 'access-token').
            and_return(gc_client)

          gc_customers_service =
            instance_double(GoCardlessPro::Services::CustomersService)

          expect(gc_client).
            to receive(:customers).
            and_return(gc_customers_service)

          customer = instance_double(GoCardlessPro::Resources::Customer,
                                     id: 'CU123',
                                     email: 'someone@example.com')

          # TODO: paginate using `all`
          expect(gc_customers_service).
            to receive(:list).
            and_return(instance_double(GoCardlessPro::ListResponse, records: [customer]))

          gc_mandates_service = instance_double(GoCardlessPro::Services::MandatesService)

          mandate = instance_double(GoCardlessPro::Resources::Mandate, id: 'MD123')

          expect(gc_client).
            to receive(:mandates).
            and_return(gc_mandates_service)

          # TODO: paginate using `all`
          expect(gc_mandates_service).
            to receive(:list).
            with(params: { customer: 'CU123' }).
            and_return(instance_double(GoCardlessPro::ListResponse, records: [mandate]))

          gc_payments_service = instance_double(GoCardlessPro::Services::PaymentsService)

          expect(gc_client).
            to receive(:payments).
            and_return(gc_payments_service)

          expect(gc_payments_service).
            to receive(:create).
            with(
              amount: 1000,
              currency: 'GBP',
              links: { mandate: 'MD123' }
            )

          slack_messages.call
        end
      end

      context "but doesn't have an active mandate" do
        it 'sends an error message'
      end
    end

    context "with a recipient that doesn't exist" do
      it 'sends an error message'
    end
  end
end
