module ChaosDetector
  module GraphTheory
    class NodeMetrics
      attr_accessor :afferent_couplings
      attr_accessor :efferent_couplings
      attr_accessor :terminal_routes
      attr_accessor :circular_routes


      def initialize(afferent_couplings: 0, efferent_couplings: 0, terminal_routes:, circular_routes:)
        @afferent_couplings = afferent_couplings
        @efferent_couplings = efferent_couplings
        @terminal_routes = terminal_routes || []
        @circular_routes = circular_routes || []
      end

      # https://en.wikipedia.org/wiki/Software_package_metrics
      # I = Ce / (Ce + Ca).
      # I = efferent_couplings / (total couplings)
      # Value from 0.0 to 1.0
      # I = 0.0 is maximally stable while
      # I = 1.0 is maximally unstable.
      def instability
        cT = total_couplings
        cT == 0 ? 0.0 : @efferent_couplings / cT
      end

      def total_couplings
        @afferent_couplings + @efferent_couplings
      end

      def to_s
        "Ce: #{@efferent_couplings}, Ca: #{@afferent_couplings}, I: #{instability}"
      end

    end
  end
end