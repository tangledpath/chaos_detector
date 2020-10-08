require 'forwardable'

module ChaosDetector
  module GraphTheory
    class NodeMetrics
      extend Forwardable
      attr_accessor :afference
      attr_accessor :efference
      attr_accessor :terminal_routes
      attr_accessor :circular_routes
      attr_reader :node

      def_delegators :@node, :title, :subtitle

      def reduced_sum
        @node&.reduction&.reduction_sum
      end

      def reduction_count
        @node&.reduction&.reduction_count
      end

      def initialize(node, afference: 0, efference: 0, terminal_routes:, circular_routes:)
        raise ArgumentError("node is required") if node.nil?

        @node = node
        @afference = afference
        @efference = efference
        @terminal_routes = terminal_routes || []
        @circular_routes = circular_routes || []
      end

      # https://en.wikipedia.org/wiki/Software_package_metrics
      # I = Ce / (Ce + Ca).
      # I = efference / (total couplings)
      # Value from 0.0 to 1.0
      # I = 0.0 is maximally stable while
      # I = 1.0 is maximally unstable.
      def instability
        cT = total_couplings.to_f
        (cT.zero?) ? 0.0 : @efference / cT
      end

      def total_couplings
        @afference + @efference
      end

      def summary
        'I = Ce / (Ce + Ca)'
      end

      def to_s
        "Ce: #{@efference}, Ca: #{@afference}, I: #{instability}"
      end
    end
  end
end
