# frozen_string_literal: true

require 'gocardless_pro'
require_relative '../../../lib/gc_me/middleware/get_gc_mandate'
require_relative '../../../lib/gc_me/gc_client'
require_relative '../../../lib/gc_me/middleware/parse_payment_message'

RSpec.describe GCMe::Middleware::GetGCMandate do
  context 'when the mandate exists' do
    it 'provides the mandate from the GC api' do
      next_middleware = double
      gc_client       = instance_double(GCMe::GCClient)
      customer        = double
      context         = { gc_client: gc_client, gc_customer: customer }
      mandate         = double

      subject = GCMe::Middleware::GetGCMandate.new(context, next_middleware)

      expect(gc_client).
        to receive(:get_active_mandate).
        with(customer).
        and_return(mandate)

      expect(next_middleware).to receive(:call)

      expect(subject).
        to receive(:provide).
        with(gc_mandate: mandate)

      subject.call
    end
  end

  context 'when the mandate does not exist' do
    it 'responds with an error message' do
      next_middleware = double
      gc_client       = instance_double(GCMe::GCClient)
      customer        = instance_double(GoCardlessPro::Resources::Customer,
                                        email: 'someone@example.com')
      context         = { gc_client: gc_client, gc_customer: customer }

      subject = GCMe::Middleware::GetGCMandate.new(context, next_middleware)

      expect(gc_client).
        to receive(:get_active_mandate).
        with(customer).
        and_return(nil)

      expect(next_middleware).to_not receive(:call)

      _status, _headers, body = subject.call

      expect(body.first).to include('someone@example.com does not have an active mandate')
    end
  end
end
