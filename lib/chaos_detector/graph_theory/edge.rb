module ChaosDetector
module GraphTheory
  class Edge
    attr_reader :src_node
    attr_reader :dep_node
    attr_reader :reduce_cnt

    def initialize(src_node, dep_node, reduce_cnt:1)
      raise ArgumentError, "src_node is required " unless src_node
      raise ArgumentError, "dep_node is required " unless dep_node
      @src_node = src_node
      @dep_node = dep_node
      @reduce_cnt = reduce_cnt
    end

    def ==(other)
      self.src == other.src &&
      self.dep == other.dep
    end

    def to_s()
      s = "[%s] -> [%s]" % [src_node.label, dep_node.label]
      s << "(#{reduce_cnt})" if reduce_cnt > 1
      s
    end
  end
end
end