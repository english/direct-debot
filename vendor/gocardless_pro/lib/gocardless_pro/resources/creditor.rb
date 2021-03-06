

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
  # Each [payment](#core-endpoints-payments) taken through the API is linked to
  # a "creditor", to whom the payment is then paid out. In most cases your
  # organisation will have a single "creditor", but the API also supports
  # collecting payments on behalf of others.
  # 
  # Please get in touch if you
  # wish to use this endpoint. Currently, for Anti Money Laundering reasons, any
  # creditors you add must be directly related to your organisation.
    # Represents an instance of a creditor resource returned from the API
    class Creditor
      
      
      attr_reader :address_line1
      
      attr_reader :address_line2
      
      attr_reader :address_line3
      
      attr_reader :city
      
      attr_reader :country_code
      
      attr_reader :created_at
      
      attr_reader :id
      
      
      attr_reader :name
      
      attr_reader :postal_code
      
      attr_reader :region
      # initialize a resource instance
      # @param object [Hash] an object returned from the API
      def initialize(object, response = nil)
        @object = object
        
        @address_line1 = object["address_line1"]
        @address_line2 = object["address_line2"]
        @address_line3 = object["address_line3"]
        @city = object["city"]
        @country_code = object["country_code"]
        @created_at = object["created_at"]
        @id = object["id"]
        @links = object["links"]
        @name = object["name"]
        @postal_code = object["postal_code"]
        @region = object["region"]
        @response = response
      end

      def api_response
        ApiResponse.new(@response)
      end

      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      # return the links that the resource has
      def links
        valid_link_keys = %w(default_eur_payout_account default_gbp_payout_account default_sek_payout_account )
        valid_links = (@links || {}).select { |key, _| valid_link_keys.include?(key) }

        links_class = Struct.new(
          *{
          
            default_eur_payout_account: "",
          
            default_gbp_payout_account: "",
          
            default_sek_payout_account: "",
          
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
