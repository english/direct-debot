module GCMe
  # wrapper around the GoCardlessPro client
  class GCClient
    def initialize(client)
      @client = client
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
        find { |mandate| mandate.status == 'active' }
    end

    def create_payment(mandate, currency, pence)
      attributes = { amount: pence, currency: currency, links: { mandate: mandate.id } }

      @client.
        payments.
        create(params: attributes)
    end

    def create_redirect_flow(success_redirect_url)
      attributes = { success_redirect_url: success_redirect_url, session_token: '1' }

      @client.
        redirect_flows.
        create(params: attributes)
    end
  end
end
