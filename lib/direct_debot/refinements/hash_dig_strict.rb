module DirectDebot
  module Refinements
    # Add ActiveSupport Hash#slice as well as a 'strict' Hash#slice!
    module HashDigStrict
      refine Hash do
        def dig!(*keys)
          keys.reduce(self, &:fetch)
        end
      end
    end
  end
end
