# frozen_string_literal: true

require 'json_schema'
require_relative '../../../../lib/direct_debot/routes/slack_messages'

RSpec::Matchers.define :validate do |data|
  match { |schema| schema.validate(data).first }
end

RSpec.describe DirectDebot::Routes::SlackMessages::Handler::SCHEMA do
  let(:valid_params) do
    {
      'token'        => 'gIkuvaNzQIHg97ATvDxqgjtO',
      'team_id'      => 'T0001',
      'team_domain'  => 'example',
      'channel_id'   => 'C2147483705',
      'channel_name' => 'test',
      'user_id'      => 'U2147483697',
      'user_name'    => 'Steve',
      'command'      => '/direct-debot',
      'text'         => '£10 from @jane'
    }
  end

  let(:schema) { JsonSchema.parse!(described_class) }

  it 'knows what valid params are' do
    expect(schema).to validate(valid_params)
  end

  it "validates 'authorise' messages" do
    expect(schema).to validate(valid_params.merge('text' => 'authorise'))
    expect(schema).to_not validate(valid_params.merge('text' => 'authorize'))
  end

  it "validates 'payment' messages" do
    expect(schema).to validate(valid_params.merge('text' => '€3.80 from someone'))
    expect(schema).to_not validate(valid_params.merge('text' => '$3.80 from someone'))
  end

  it "validates 'add customer' messages" do
    expect(schema).to validate(valid_params.merge('text' => 'customers add foo@bar.com'))

    expect(schema).to_not validate(valid_params.merge('text' => 'customers add foo'))
    expect(schema).to_not validate(valid_params.merge('text' => 'customers add @jane'))
  end
end
