require 'gocardless_pro'

module GCMe
  class GCClient
    def initialize(environment, access_token)
      @client = GoCardlessPro::Client.new(environment: environment,
                                          access_token: access_token)
    end

    def get_customer(email)
      @client.customers.list.records.find { |customer| customer.email == email }
    end

    def get_active_mandate(customer)
      @client.mandates.list(params: { customer: customer.id }).records.
        find { |mandate| mandate.status == 'active' }
    end

    def create_payment(mandate, currency, pence)
      attributes = { amount: pence, currency: currency, links: { mandate: mandate.id } }

      @client.payments.create(params: attributes)
    end
  end
end
