require 'chaos_detector/graph_theory/node'
# Domain node
module ChaosDetector
  module ChaosGraphs
    class DomainNode < ChaosDetector::GraphTheory::Node
      alias domain_name name

      def initialize(domain_name: nil, node_origin: nil, is_root: false, reduction: nil)
        super(name: domain_name, root: is_root, node_origin: node_origin, reduction: reduction)
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
        root? ? 'Root Node' : ''
      end

      def graph_props
        props = super
        if reduction
          props.merge!(
            cardinality_modules: reduction.reduction_count,
            cardinality_functions: reduction.reduction_sum
          )
        end
        super.merge(props)
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
