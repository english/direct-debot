

# encoding: utf-8
#
# WARNING: Do not edit by hand, this file was generated by Crank:
#
#   https://github.com/gocardless/crank
#
require 'uri'

module GoCardlessPro
  # A module containing classes for each of the resources in the GC Api
  module Resources
  # Payment objects represent payments from a
  # [customer](#core-endpoints-customers) to a
  # [creditor](#whitelabel-partner-endpoints-creditors), taken against a Direct
  # Debit [mandate](#core-endpoints-mandates).
  # 
  # GoCardless will notify
  # you via a [webhook](#webhooks) whenever the state of a payment changes.
    # Represents an instance of a payment resource returned from the API
    class Payment
      
      
      attr_reader :amount
      
      attr_reader :amount_refunded
      
      attr_reader :charge_date
      
      attr_reader :created_at
      
      attr_reader :currency
      
      attr_reader :description
      
      attr_reader :id
      
      
      attr_reader :metadata
      
      attr_reader :reference
      
      attr_reader :status
      # initialize a resource instance
      # @param object [Hash] an object returned from the API
      def initialize(object, response = nil)
        @object = object
        
        @amount = object["amount"]
        @amount_refunded = object["amount_refunded"]
        @charge_date = object["charge_date"]
        @created_at = object["created_at"]
        @currency = object["currency"]
        @description = object["description"]
        @id = object["id"]
        @links = object["links"]
        @metadata = object["metadata"]
        @reference = object["reference"]
        @status = object["status"]
        @response = response
      end

      def api_response
        ApiResponse.new(@response)
      end

      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      # return the links that the resource has
      def links
        valid_link_keys = %w(creditor mandate payout subscription )
        valid_links = (@links || {}).select { |key, _| valid_link_keys.include?(key) }

        links_class = Struct.new(
          *{
          
            creditor: "",
          
            mandate: "",
          
            payout: "",
          
            subscription: "",
          
          }.keys
        ) do
          def initialize(hash)
            hash.each do |key, val|
              send("#{key}=", val)
            end
          end
        end
        links_class.new(valid_links)
      end
      
      
      
      
      
      
      
      

      # Provides the resource as a hash of all it's readable attributes
      def to_h
        @object
      end
    end

  end
end
