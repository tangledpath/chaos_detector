# Maintains all nodes and edges as stack calls are pushed and popped via Frames.
module ChaosDetector
  module GraphTheory
    class LoopDetector
      def initialize(detection: :simple, lookback: 0, tolerance: 0, grace_period: 0)
        @detection = detection
        @lookback = lookback
        @tolerance = tolerance
        @grace_period = grace_period
      end

      def tolerates?(nodes, node)
        return true if (nodes.length <= @grace_period)
        # return false if (lookback.zero? && tolerance.zero? && nodes.include?(node))

        # TODO: lookback
        nodes.count(node) > tolerance

      end

      private
        def form_lookback
        end

      class << self
        def simple
          @simple ||= LoopDetector.new
        end
      end
    end
  end
end
