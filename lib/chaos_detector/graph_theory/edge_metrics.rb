module ChaosDetector::GraphTheory
  class EdgeMetrics
    attr_accessor :src_count
    attr_accessor :dep_count

    def initialize
      @src_count = 0
      @dep_count = 0
    end

    def to_s
      "Dependent(from) Count: %d, Dependee(to) Count: %d, "
    end
  end
end