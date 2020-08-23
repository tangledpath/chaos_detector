# Trackking of reduction(merging/removing dups)
require 'set'
module ChaosDetector
  module GraphTheory
    class Reduction
      attr_reader :reduction_count
      attr_reader :reduction_sum

      def initialize(reduction_count: 1, reduction_sum: 1)
        @reduction_count = reduction_count
        @reduction_sum = reduction_sum
      end

      def merge!(other)
        @reduction_sum += (other&.reduction_count || 1)
        @reduction_count += 1 #(other&.reduction_count || 1)
        self
      end

      def to_s
        'Reduction (count/sum)=(%d, %d)' % [reduction_count, reduction_sum]
      end

      class << self
        def combine(primary, secondary)
          raise ArgumentError, ('Argument #primary should be Reduction object (was %s)' % primary.class) unless primary.is_a?(ChaosDetector::GraphTheory::Reduction)
          # raise ArgumentError, ('Argument #secondary should be Reduction object (was %s)' % secondary.class) unless secondary.is_a?(ChaosDetector::GraphTheory::Reduction)

          combined = primary ? primary.clone(freeze: false) : ChaosDetector::GraphTheory::Reduction.new
          combined.merge!(secondary)
        end

        def combine_all(reductions)
          red_sum = reductions.reduce(0) { |tally, r| tally + (r ? r.reduction_count : 1) }
          Reduction.new(reduction_count: reductions.count, reduction_sum: red_sum)
        end
      end
    end
  end
end
