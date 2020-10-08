# Trackking of reduction(merging/removing dups)
require 'set'
module ChaosDetector
  module GraphTheory
    class Reduction
      attr_reader :reduction_count
      attr_reader :reduction_sum

      def initialize(count:1, sum: 1)
        @reduction_count = count
        @reduction_sum = sum
      end

      def merge!(other)
        @reduction_sum += (other&.reduction_sum || 1)
        @reduction_count += (other&.reduction_count || 1)
      end

      class << self
        def combine(primary, secondary)
          reduction = primary || Reduction.new
          reduction.merge(secondary)
        end

        def combine_all(reductions)
          rsum = 0
          rcnt = 0


          reductions.reduce(Set.new) do |memo, r|
            if r.nil?
              rsum += 1
              rcnt += 1
            else
              rsum += r.reduction_sum
              rcnt += r.reduction_count
            end
          end

          Reduction.new(sum: rsum, count: rcnt)
        end
      end


    end
  end
end
