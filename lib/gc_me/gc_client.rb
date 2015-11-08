require 'gocardless_pro'

module GCMe
  # wraps the GoCardlessPro::Client
  class GCClient
    class CustomerNotFoundError < StandardError
    end

    def initialize(environment)
      @environment = environment
    end

    def create_payment(currency, pence, email, access_token)
      client = GoCardlessPro::Client.new(environment: @environment,
                                         access_token: access_token)

      mandate = get_mandate(client, email)

      client.payments.create(params: {
                               amount: pence,
                               currency: currency,
                               links: { mandate: mandate.id }
                             })
    end

    private

    def get_mandate(client, email)
      customer = get_customer(client, email)
      raise CustomerNotFoundError, "GC customer #{email} not found" unless customer

      client.mandates.list(params: { customer: customer.id }).records.first
    end

    def get_customer(client, email)
      client.customers.list.records.find { |customer| customer.email == email }
    end
  end
end
