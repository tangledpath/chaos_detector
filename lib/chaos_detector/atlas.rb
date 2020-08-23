require 'digest'
require 'matrix'
require 'set'

require 'chaos_detector/edge'
require 'chaos_detector/node'
require 'chaos_detector/options'
require 'chaos_detector/stack_frame'
require 'chaos_detector/utils'
require 'chaos_detector/graph_theory/stack_metrics'

# Maintains all nodes and edges as stack calls are pushed and popped via StackFrames.
class ChaosDetector::Atlas
  extend ChaosDetector::Utils::ChaosAttr

  FULL_TOLERANCE = 6
  PARTIAL_TOLERANCE = 3
  BASE_TOLERANCE = 1

  INDENT = " ".freeze
  attr_reader :root_node
  chaos_attr (:options) { ChaosDetector::Options.new }
  chaos_attr :nodes, []
  chaos_attr :edges, []
  chaos_attr :frame_stack, []
  chaos_attr :offset, 0
  chaos_attr :frames_nopop, []

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
    @root_node = ChaosDetector::Node.new(root: true)
    @md5 = Digest::MD5.new
    @nodes = [@root_node]
    @edges = []
    @frame_stack = []
    @frames_nopop = []
    @offset = 0

    @traversal_stats = ChaosDetector::GraphTheory::StackMetrics.new
  end

  def stack_depth
    @frame_stack.length
  end

  # @return Node matching given frame.  If already in @nodes,
  # that is returned, otherwise, a new one is created.
  def node_for_frame(frame:)
    node = @nodes.find do |n|
      n.mod_name == frame.mod_name &&
      (n.domain_name == frame.domain_name || n.mod_path == frame.mod_path)
    end

    unless node
      puts "*****************Adding to nodes(#{@nodes.length}): #{frame.mod_name}(#{frame.domain_name}) -- #{frame.mod_path}:L#{frame.line_num}"
      @nodes << node=ChaosDetector::Node.new(domain_name: frame.domain_name, mod_name: frame.mod_name, mod_path: frame.mod_path)
    end

    node
  end

  def edge_for_nodes(src_node:, dep_node:)
    edge = @edges.find do |e|
      e.src_node == src_node && e.dep_node == dep_node
    end

    unless edge
      @edges << edge=ChaosDetector::Edge.new(src_node: src_node, dep_node: dep_node)
    end

    edge
  end

  def fn_for_frame(frame:)
    return nil unless frame

    ChaosDetector::Edge::FnCall.new(fn_name: frame.fn_name, line_num: frame.line_num)
  end

  def frames_fn_couplet(frame_src:, frame_dep:)
    ChaosDetector::Edge::FnCallCouplet.new(
      src: fn_for_frame(frame_src),
      dep: fn_for_frame(frame_dep)
    )
  end

  def peek_stack
    @frame_stack.first
  end

  def stack_match(current_frame)
    raise ArgumentError, "Current Frame is required" if current_frame.nil?

    # Ranking to index:
    best_index = nil
    best_rank = -1
    best_sim = nil
    window = @offset + FULL_TOLERANCE

    @frame_stack[0..window].each_with_index do |f, n|
      sim_rank = Kernel.with(current_frame.match?(f)) do |similarity|
        if ChaosDetector::StackFrame::VERY_SIMILAR.include?(similarity)
          [similarity, FULL_TOLERANCE]
        elsif similarity==ChaosDetector::StackFrame::SimilarityRating::PARTIAL
          [similarity, PARTIAL_TOLERANCE]
        elsif similarity==ChaosDetector::StackFrame::SimilarityRating::BASE
          [similarity, BASE_TOLERANCE]
        else
          nil
        end
      end

      if sim_rank
        rank = window - n + sim_rank[1]
        if rank > best_rank
          best_index = n
          best_rank = rank
          best_sim = sim_rank[0]
        end
      end
    end

    [best_index, best_sim]
  end

  def open_frame(frame:)
    # stack_len = @frame_stack.length
    # exit(false) if stack_len > 25
    # indent = INDENT * stack_len

    dep_node = node_for_frame(frame: frame)

    prev_frame = peek_stack
    src_node = prev_frame ? node_for_frame(frame: prev_frame) : @root_node

    edge = edge_for_nodes(src_node: src_node, dep_node: dep_node)

    # Add function-level info
    edge.add_fn_couplet(
      fn_call_src: fn_for_frame(frame:prev_frame),
      fn_call_dep: fn_for_frame(frame:frame)
    )

    @frame_stack.unshift(frame)
    @traversal_stats.record_open_action()
  end

  def close_frame(frame:)
    stack_match(frame).tap do |frame_n, similarity|

      @traversal_stats.record_close_action(frame_n, similarity)
      if !frame_n.nil?
        @offset = frame_n
        @frame_stack.delete_at(frame_n)
      end
    end
  end

  def to_s
    "Nodes: %d, Edges: %d, Frames: %d" % [@nodes.length, @edges.length, @frame_stack.length]
  end

  private
    def count_depth
      -1
    end

    def count_breadth
      -1
    end

end