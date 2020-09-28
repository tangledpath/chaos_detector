module ChaosDetector
  module GraphTheory
    class Edge
      attr_reader :edge_type
      attr_reader :src_node
      attr_reader :dep_node
      attr_reader :reduce_cnt

      def initialize(src_node, dep_node, edge_type: :default, reduce_cnt: 1)
        raise ArgumentError, 'src_node is required ' unless src_node
        raise ArgumentError, 'dep_node is required ' unless dep_node

        @src_node = src_node
        @dep_node = dep_node
        @reduce_cnt = reduce_cnt
        @edge_type = edge_type
      end

      def hash
        [@src_node, @dep_node].hash
      end

      def eql?(other)
        self == other
      end

      def ==(other)
        # puts "Checking src and dep"
        src_node == other.src_node && dep_node == other.dep_node
      end

      def to_s
        s = format('[%s] -> [%s]', src_node.label, dep_node.label)
        s << "(#{reduce_cnt})" if reduce_cnt > 1
        s
      end
    end
  end
end
