require 'active_support/concern'
require 'action_dispatch/http/request'
require 'lotus/router'
require 'json_schema'
require_relative '../../../lib/gc_me/routes/slack_messages'
require_relative '../../../lib/gc_me/db/store'

RSpec.describe GCMe::Routes::SlackMessages do
  # token=gIkuvaNzQIHg97ATvDxqgjtO
  # team_id=T0001
  # team_domain=example
  # channel_id=C2147483705
  # channel_name=test
  # user_id=U2147483697
  # user_name=Steve
  # command=/weather
  # text=94070
  context 'schema validation' do
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

    context 'with an authorise message' do
      it 'is happy' do
        params = valid_params.merge(text: 'authorise')
        valid, * = schema.validate(params)

        expect(valid).to be(true)
      end

      it "isn't lenient" do
        params = valid_params.merge(text: 'authorize')
        valid, * = schema.validate(params)

        expect(valid).to be(true)
      end
    end

    context 'with a transaction message' do
      it 'is happy' do
        amounts = ['10', '0.1', '1.50']
        valid_currencies = ['€', '£']
        invalid_currencies = ['', 'a', '$', '£']

        build_schema = -> (currency, amount) do
          params = valid_params.merge(text: "#{currency}#{amount} from @jane")
          valid, * = schema.validate(params)

          valid
        end

        valid_currencies.product(amounts).map(&build_schema).each do |valid|
          expect(valid).to be(true)
        end

        invalid_currencies.product(amounts).map(&build_schema).each do |valid|
          expect(valid).to be(false)
        end
      end

      context 'with a slack name'
      context 'with an email'
    end
  end
end
