

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
  # Mandates represent the Direct Debit mandate with a
  # [customer](#core-endpoints-customers).
  # 
  # GoCardless will notify you
  # via a [webhook](#webhooks) whenever the status of a mandate changes.
    # Represents an instance of a mandate resource returned from the API
    class Mandate
      
      
      attr_reader :created_at
      
      attr_reader :id
      
      
      attr_reader :metadata
      
      attr_reader :next_possible_charge_date
      
      attr_reader :reference
      
      attr_reader :scheme
      
      attr_reader :status
      # initialize a resource instance
      # @param object [Hash] an object returned from the API
      def initialize(object, response = nil)
        @object = object
        
        @created_at = object["created_at"]
        @id = object["id"]
        @links = object["links"]
        @metadata = object["metadata"]
        @next_possible_charge_date = object["next_possible_charge_date"]
        @reference = object["reference"]
        @scheme = object["scheme"]
        @status = object["status"]
        @response = response
      end

      def api_response
        ApiResponse.new(@response)
      end

      
      
      
      
      
      
      # return the links that the resource has
      def links
        valid_link_keys = %w(creditor customer_bank_account )
        valid_links = (@links || {}).select { |key, _| valid_link_keys.include?(key) }

        links_class = Struct.new(
          *{
          
            creditor: "",
          
            customer_bank_account: "",
          
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