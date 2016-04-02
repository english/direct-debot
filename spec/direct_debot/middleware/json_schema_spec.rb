# frozen_string_literal: true

require_relative '../../../lib/direct_debot/middleware/json_schema'

RSpec.describe DirectDebot::Middleware::JSONSchema do
  subject(:middleware) do
    context = { request: double(params: params) }

    described_class.new(context, null_middleware, schema: schema)
  end

  let(:schema) do
    {
      'type' => 'object',
      'additionalProperties' => false,
      'properties' => {
        'foo' => { 'type' => 'string' }
      }
    }
  end

  context 'with valid params' do
    let(:params) { { 'foo' => 'bar' } }

    it { is_expected.to call_next_middleware }
  end

  context 'with invalid params' do
    let(:params) { { 'foo' => 123 } }

    it { is_expected.to_not call_next_middleware }
    it { is_expected.to respond_with_status(400) }
    it { is_expected.to respond_with_body_that_matches('123 is not a string') }
  end
end
