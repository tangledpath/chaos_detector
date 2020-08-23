module ChaosDetector::GraphTheory
  # Nodes per domain
  # Edges per domain
  class DomainMetrics
    attr_reader :dep_count
    attr_reader :dep_count_norm

    def initialize
      @dep_count = 0
      @dep_count_norm = 0.0
    end

    def to_s

    end
  end
end