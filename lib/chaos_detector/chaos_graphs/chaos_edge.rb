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

      # association
      REF_TYPES = %i{ generalization association aggregation composition }.freeze
      def initialize(src_node, dep_node, reduce_cnt:1)
        super
        # @domain_graph = nil
      end

      def log(msg)
        ChaosUtils::log_msg(msg, subject: "ChaosEdge")
      end
  end
  end
end