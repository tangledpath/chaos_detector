require 'forwardable'

require 'digest'
require 'matrix'
require 'chaos_detector/edge'
require 'chaos_detector/graphus'
require 'chaos_detector/nodes/function_node'
require 'chaos_detector/options'
require 'chaos_detector/stack_frame'
require 'chaos_detector/utils'
require 'chaos_detector/graph_theory/stack_metrics'

# Maintains all nodes and edges as stack calls are pushed and popped via StackFrames.
class ChaosDetector::Atlas
  extend Forwardable
  extend ChaosDetector::Utils::ChaosAttr

  FULL_TOLERANCE = 6
  PARTIAL_TOLERANCE = 3
  BASE_TOLERANCE = 1

  INDENT = " ".freeze
  chaos_attr (:options) { ChaosDetector::Options.new }
  chaos_attr :frame_stack, []
  chaos_attr :offset, 0
  chaos_attr :frames_nopop, []

  chaos_attr (:graphus)
  def_instance_delegator :graphus, :nodes, :graph_nodes
  def_instance_delegator :graphus, :edges, :graph_edges

  # chaos_attr :log_buffer, []
  chaos_attr :traversal_stats

  def stop
    log("Stopping:\n#{@traversal_stats}")
    self
  end

  def log(msg)
    ChaosDetector::Utils.log(msg, subject: "Atlas")
  end

  def initialize(options: nil)
    @options = options unless options.nil?
    reset
  end

  def reset
    root_node = ChaosDetector::Nodes::FunctionNode.root_node(force_new: true)
    @graphus = ChaosDetector::Graphus.new(root_node: root_node)
    @md5 = Digest::MD5.new
    @frame_stack = []
    @frames_nopop = []
    @offset = 0

    @traversal_stats = ChaosDetector::GraphTheory::StackMetrics.new
  end

  def stack_depth
    @frame_stack.length
  end

  # @return Node matching given frame.  If already in nodes,
  # that is returned, otherwise, a new one is created.
  def node_for_frame(frame)
    graphus.node_for(frame) do
      ChaosDetector::Nodes::FunctionNode.new(
        fn_name: frame.fn_name,
        fn_path: frame.fn_path,
        domain_name: frame.domain_name,
        mod_name: frame.mod_name,
        mod_type: frame.mod_type
      )
    end
  end

  def peek_stack
    @frame_stack.first
  end

  def stack_match(current_frame)
    raise ArgumentError, "Current Frame is required" if current_frame.nil?

    @frame_stack.index do |f|
      ChaosDetector::Nodes::FunctionNode.key_attributes_match?(f, current_frame)
    end
  end

  def open_frame(frame)
    # stack_len = @frame_stack.length
    # exit(false) if stack_len > 25
    # indent = INDENT * stack_len
    raise ArgumentError, "#open_frame requires frame" if frame.nil?

    dep_node = node_for_frame(frame)
    prev_frame = peek_stack
    if prev_frame == frame
      dep_node.add_module(frame.mod_info)
    end

    src_node = prev_frame ? node_for_frame(prev_frame) : graphus.root_node

    _edge = graphus.edge_for_nodes(src_node, dep_node)

    @frame_stack.unshift(frame)
    @traversal_stats.record_open_action()
  end

  def close_frame(frame)
    stack_match(frame).tap do |frame_n|
      @traversal_stats.record_close_action(frame_n)
      if !frame_n.nil?
        @frame_stack.slice!(0..frame_n)
      end
    end
  end

  def to_s
    "%s, Frames: %d" % [graphus, frame_stack.length]
  end

  def inspect
    buffy = [to_s]
    buffy << graphus.inspect
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