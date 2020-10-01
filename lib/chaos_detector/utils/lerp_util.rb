module ChaosDetector
  module Utils
    module LerpUtil
      class << self
        def delerp(val, min:, max:)
          return 0.0 if min==max
          (val - min).to_f / (max - min)
        end

        # Linear interpolation between min and max:
        # @arg pct is percentage where 1.0 represents 100%
        def lerp(pct, min:, max:)
          return 0.0 if min==max
          (max-min) * pct.to_f + min
        end
      end
    end
  end
end
