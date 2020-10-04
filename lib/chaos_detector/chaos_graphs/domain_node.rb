require 'chaos_detector/graph_theory/node'
# Domain node
module ChaosDetector
  module ChaosGraphs
    class DomainNode < ChaosDetector::GraphTheory::Node
      alias domain_name name
      attr_reader :reduce_count

      def initialize(domain_name: nil, node_origin: nil, is_root: false, reduce_count: nil)
        super(name: domain_name, root: is_root, node_origin: node_origin)
        @reduce_count = reduce_count
      end

      def hash
        domain_name.hash
      end

      def eql?(other)
        self == other
      end

      def ==(other)
        domain_name&.to_s == other&.domain_name&.to_s
      end

      def title
        super
      end

      def subtitle
        "Reduced: #{reduce_count}"
      end

      # Must be name/domain_name for comparisons:
      def to_s
        domain_name
      end

      class << self
        attr_reader :root_node
        def root_node(force_new: false)
          @root_node = new(is_root: true) if force_new || @root_node.nil?
          @root_node
        end
      end
    end
  end
end
