require 'forwardable'

require 'chaos_detector/graph_theory/edge'
require 'chaos_detector/graph_theory/graph'
require_relative 'chaos_graphs/function_node'
require_relative 'stacker/frame_stack'
require_relative 'stacker/frame'
require_relative 'atlas_metrics'
require 'chaos_detector/refined_utils'

using ChaosDetector::RefinedUtils

# Maintains all nodes and edges as stack calls are pushed and popped via Frames.
module ChaosDetector
  class Atlas
    extend Forwardable

    attr_reader :frame_stack
    attr_reader :graph
    attr_reader :atlas_metrics

    def_delegator :@frame_stack, :depth, :stack_depth
    def_delegator :@graph, :node_count
    def_delegator :@graph, :edge_count

    def initialize()
      @frame_stack = ChaosDetector::Stacker::FrameStack.new
      root_node = ChaosDetector::ChaosGraphs::FunctionNode.root_node(force_new: true)
      @graph = ChaosDetector::GraphTheory::Graph.new(root_node: root_node)
      @atlas_metrics = ChaosDetector::AtlasMetrics.new
    end

    def log(msg)
      log_msg(msg, subject: "Atlas")
    end

    def stop
      log("Stopping:\n#{@atlas_metrics}")
      self
    end

    # @return Node matching given frame.  If already in nodes,
    # that is returned, otherwise, a new one is created.
    def node_for_frame(frame)
      graph.node_for(frame) do
        ChaosDetector::ChaosGraphs::FunctionNode.new(
          fn_name: frame.fn_name,
          fn_path: frame.fn_path,
          domain_name: frame.domain_name,
          mod_name: frame.mod_name,
          mod_type: frame.mod_type
        )
      end
    end

    def open_frame(frame)
      raise ArgumentError, "#open_frame requires frame" if frame.nil?

      dep_node = node_for_frame(frame)
      prev_frame = @frame_stack.peek
      if prev_frame == frame && aught?(frame.mod_name)
        dep_node.add_module_attrs(mod_name:frame.mod_name, mod_path: frame.fn_path, mod_type: frame.mod_type)
      end

      src_node = prev_frame ? node_for_frame(prev_frame) : graph.root_node

      _edge = graph.edge_for_nodes(src_node, dep_node)

      @frame_stack.push(frame)
      @atlas_metrics.record_open_action()
    end

    def close_frame(frame)
      @frame_stack.pop(frame).tap do |n_frame|
        @atlas_metrics.record_close_action(n_frame)
      end
    end

    def to_s
      "%s, Frames: %d" % [graph, stack_depth]
    end

    def inspect
      buffy = [to_s]
      buffy << graph.inspect
      buffy.join("\n")
    end

    private
      def count_depth
        -1
      end

      def count_breadth
        -1
      end

  end
end