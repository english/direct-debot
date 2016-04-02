module DirectDebot
  module Refinements
    # Add ActiveSupport Hash#slice as well as a 'strict' Hash#slice!
    module HashSlice
      refine Hash do
        def slice(*keys)
          keys.each_with_object({}) { |k, hash| hash[k] = self[k] if key?(k) }
        end

        def slice!(*keys)
          keys.each_with_object({}) { |k, hash| hash[k] = fetch(k) }
        end
      end
    end
  end
end
