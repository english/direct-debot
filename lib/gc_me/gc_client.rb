require 'gocardless_pro'

module GCMe
  # wraps the GoCardlessPro::Client
  class GCClient
    class CustomerNotFoundError < StandardError
    end

    class ActiveMandateNotFoundError < StandardError
    end

    def initialize(environment)
      @environment = environment
    end

    def create_payment(currency, pence, email, access_token)
      client = GoCardlessPro::Client.new(environment: @environment,
                                         access_token: access_token)

      mandate = get_active_mandate(client, email)

      unless mandate
        fail ActiveMandateNotFoundError, "Active GC mandate for #{email} not found"
      end

      attributes = { amount: pence, currency: currency, links: { mandate: mandate.id } }

      client.payments.create(params: attributes)
    end

    private

    def get_active_mandate(client, email)
      customer = get_customer(client, email)
      fail CustomerNotFoundError, "GC customer #{email} not found" unless customer

      client.mandates.list(params: { customer: customer.id }).records.
        find { |mandate| mandate.status == 'active' }
    end

    def get_customer(client, email)
      client.customers.list.records.find { |customer| customer.email == email }
    end
  end
end
