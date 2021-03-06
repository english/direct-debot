

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
  # Payouts represent transfers from GoCardless to a
  # [creditor](#whitelabel-partner-endpoints-creditors). Each payout contains
  # the funds collected from one or many [payments](#core-endpoints-payments).
  # Payouts are created automatically after a payment has been successfully
  # collected.
    # Represents an instance of a payout resource returned from the API
    class Payout
      
      
      attr_reader :amount
      
      attr_reader :created_at
      
      attr_reader :currency
      
      attr_reader :id
      
      
      attr_reader :reference
      
      attr_reader :status
      # initialize a resource instance
      # @param object [Hash] an object returned from the API
      def initialize(object, response = nil)
        @object = object
        
        @amount = object["amount"]
        @created_at = object["created_at"]
        @currency = object["currency"]
        @id = object["id"]
        @links = object["links"]
        @reference = object["reference"]
        @status = object["status"]
        @response = response
      end

      def api_response
        ApiResponse.new(@response)
      end

      
      
      
      
      
      
      
      
      
      
      # return the links that the resource has
      def links
        valid_link_keys = %w(creditor creditor_bank_account )
        valid_links = (@links || {}).select { |key, _| valid_link_keys.include?(key) }

        links_class = Struct.new(
          *{
          
            creditor: "",
          
            creditor_bank_account: "",
          
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
