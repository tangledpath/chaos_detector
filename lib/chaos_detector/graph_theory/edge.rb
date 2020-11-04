module ChaosDetector
  module GraphTheory
    class Edge
      attr_accessor :edge_type
      attr_writer :graph_props
      attr_accessor :src_node
      attr_accessor :dep_node
      attr_accessor :reduction

      EDGE_TYPES = {
        default: 0,
        superclass: 1,
        association: 2,
        class_association: 3
      }.freeze

      def initialize(src_node, dep_node, edge_type: :default, reduction: nil)
        raise ArgumentError, 'src_node is required ' unless src_node
        raise ArgumentError, 'dep_node is required ' unless dep_node

        @src_node = src_node
        @dep_node = dep_node
        @reduction = reduction
        @edge_type = edge_type
        @graph_props = {}
      end

      def edge_rank
        EDGE_TYPES.fetch(@edge_type, 0)
      end

      def weight
        @reduction&.reduction_sum || 1
      end

      def hash
        [@src_node, @dep_node].hash
      end

      def eql?(other)
        self == other
      end

      # Default behavior is accessor for @graph_props
      def graph_props
        @graph_props
      end



      def ==(other)
        # puts "Checking src and dep"
        src_node == other.src_node && dep_node == other.dep_node
      end

      def to_s
        s = format('[%s] -> [%s]', src_node.title, dep_node.title)
        s << "(#{reduction.reduction_sum})" if reduction&.reduction_sum.to_i > 1
        s
      end

      # Mutate this Edge; combining attributes from other:
      def merge!(other)
        raise ArgumentError, ('Argument other should be Edge object (was %s)' % other.class) unless other.is_a?(Edge)

        if EDGE_TYPES.dig(other.edge_type) > EDGE_TYPES.dig(edge_type)
          @edge_type = other.edge_type
        end

        # puts("EDGE REDUCTION: #{@reduction.class} -- #{other.class}  // #{other.reduction.class}")
        @reduction = ChaosDetector::GraphTheory::Reduction.combine(@reduction, other.reduction)
        self
      end
    end
  end
end
