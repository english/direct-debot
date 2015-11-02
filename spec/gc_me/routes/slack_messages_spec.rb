require 'active_support/concern'
require 'action_dispatch/http/request'
require 'lotus/router'
require 'json_schema'
require_relative '../../../lib/gc_me/routes/slack_messages'
require_relative '../../../lib/gc_me/db/store'

RSpec::Matchers.define :validate do |data|
  match { |schema| schema.validate(data).first }
end

RSpec.describe GCMe::Routes::SlackMessages do
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

  # describe 'given an authorise message' do
  #   it 'returns a gc oauth link' do

  #   end
  # end

  # describe 'given a payment message' do
  #   it '' do

  #   end
  # end
end
