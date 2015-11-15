require_relative '../../../lib/gc_me/middleware/json_schema'

RSpec.describe GCMe::Middleware::JSONSchema do
  subject(:middleware) do
    context = { request: double(params: params) }

    GCMe::Middleware::JSONSchema.new(context, next_middleware, schema: schema)
  end

  let(:next_middleware) { -> {} }

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

    it 'calls the next middleware' do
      expect(next_middleware).to receive(:call)

      middleware.call
    end
  end

  context 'with invalid params' do
    let(:params) { { 'foo' => 123 } }

    it 'returns a 400' do
      status, * = middleware.call

      expect(status).to eq(400)
    end

    it 'returns errors' do
      *, body = middleware.call

      expect(body.first).to include('123 is not a string')
    end

    it "doesn't call the next middleware" do
      expect(next_middleware).to_not receive(:call)

      middleware.call
    end
  end
end
