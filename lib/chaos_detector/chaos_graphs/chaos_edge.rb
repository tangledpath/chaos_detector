require_relative 'function_node'
require_relative 'domain_node'
require_relative 'module_node'

require 'chaos_detector/graph_theory/edge'
require 'chaos_detector/graph_theory/graph'
require 'chaos_detector/chaos_utils'

# Edge with dependency-tracking attributes
module ChaosDetector
  module ChaosGraphs
    class ChaosEdge < GraphTheory::Edge
      attr_reader :dep_type

      # association
      DEP_TYPES = %i[association generalization aggregation composition].freeze
      def initialize(src_node, dep_node, dep_type: :association, reduction: nil)
        super
        @dep_type = dep_type
      end

      def to_s
        m = ChaosUtils.decorate(super, clamp: :parens, suffix: ' ')
        m << ChaosUtils.decorate(@dep_type, clamp: :parens)
      end

      def log(msg, **opts)
        ChaosUtils.log_msg(msg, subject: 'ChaosEdge', **opts)
      end
    end
  end
end
