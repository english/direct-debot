require 'active_support/concern'
require 'action_dispatch/http/request'
require 'json_schema'
require_relative '../../../lib/gc_me/oauth_client'
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
      oauth_client: oauth_client
    }
  end

  let(:oauth_client) { instance_double(GCMe::OAuthClient) }

  describe 'given an authorise message' do
    let(:params) { { 'user_id' => 'slack-user-id', text: 'authorise' } }

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
    let(:params) { { 'user_id' => 'slack-user-id', text: 'authorise' } }

    context 'with a @slackuser recipient'

    context 'with an someone@email.com address'

    context "with a recipient that doesn't exist"
  end
end
