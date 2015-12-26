# frozen_string_literal: true

module GCMe
  # wrapper around the GoCardlessPro client
  class GCClient
    REDIRECT_FLOW_SESSION_TOKEN = '1'
    ACTIVE_MANDATE_STATUSES = Set.new(%w(pending_submission submitted active))

    def initialize(client)
      @client = client
    end

    def get_customers
      @client.
        customers.
        all
    end

    def get_customer(email)
      @client.
        customers.
        all.
        find { |customer| customer.email == email }
    end

    def get_active_mandate(customer)
      @client.
        mandates.
        all(params: { customer: customer.id }).
        find { |mandate| ACTIVE_MANDATE_STATUSES.include?(mandate.status) }
    end

    def create_payment(mandate, currency, pence)
      attributes = { amount: pence, currency: currency, links: { mandate: mandate.id } }

      @client.
        payments.
        create(params: attributes)
    end

    def create_redirect_flow(success_redirect_url)
      attributes = { success_redirect_url: success_redirect_url,
                     session_token: REDIRECT_FLOW_SESSION_TOKEN }

      @client.
        redirect_flows.
        create(params: attributes)
    end

    def complete_redirect_flow(gc_redirect_flow_id)
      @client.
        redirect_flows.
        complete(gc_redirect_flow_id,
                 params: { session_token: REDIRECT_FLOW_SESSION_TOKEN })
    end
  end
end
