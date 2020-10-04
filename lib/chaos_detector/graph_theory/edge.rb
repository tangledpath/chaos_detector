module ChaosDetector
  module GraphTheory
    class Edge
      attr_accessor :edge_type
      attr_reader :src_node
      attr_reader :dep_node
      attr_accessor :reduce_count

      EDGE_TYPES = {
        default: 0,
        superclass: 1,
        association: 2,
        class_association: 3
      }.freeze

      def initialize(src_node, dep_node, edge_type: :default, reduce_count: 1)
        raise ArgumentError, 'src_node is required ' unless src_node
        raise ArgumentError, 'dep_node is required ' unless dep_node

        @src_node = src_node
        @dep_node = dep_node
        @reduce_count = reduce_count
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
        s = format('[%s] -> [%s]', src_node.title, dep_node.title)
        s << "(#{reduce_count})" if reduce_count > 1
        s
      end

      def reduce(other)
        if EDGE_TYPES.dig(other.edge_type) > EDGE_TYPES.dig(edge_type)
          @edge_type = other.edge_type
        end

        @reduce_count += other.reduce_count
      end

    end
  end
end
