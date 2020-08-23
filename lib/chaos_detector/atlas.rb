require 'digest'
require 'chaos_detector/edge'
require 'chaos_detector/node'
require 'chaos_detector/options'
require 'chaos_detector/stack_frame'
require 'chaos_detector/utils'

# TODO: add traversal types to find depth, coupling in various ways (directory/package/namespace):
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

  DomainEdge = Struct.new(:src_domain, :dep_domain)
  def domain_deps
    domain_edges = {}

    @edges.each do |edge|
      src_domain = edge.src_node&.domain_name
      dep_domain = edge.dep_node&.domain_name

      log("Checking edge: #{edge} : #{src_domain && dep_domain && src_domain != dep_domain}")
      if src_domain && dep_domain && src_domain != dep_domain
        domain_edge = DomainEdge.new(src_domain, dep_domain)
        domain_edges[domain_edge] = domain_edges.fetch(domain_edge, 0) + 1
      end
    end

    domain_edges
  end

  def stop
    log("Stopping:\n#{@traversal_stats}")
    self
  end

  def log(msg)
    ChaosDetector::Utils.log(msg, subject: "Atlas")
  end

# TODO: x
  # Report for each node
  #   outgoing
  #   incoming
  #   How many

  #  Each node couplet (Example for 100 nodes, we'd have 100 * 99 potential couplets)
  #  Capture how many other nodes depend upon both nodes in couplet [directly, indirectly]
  #  Capture how many other nodes from other domains depend upon both [directly, indirectly]
  def node_stats
  end

  #   Report edge on relative difference in its nodes:
  #   domain, path, package?
  # domain, path, package?
  # Coupling
  #
  # Overall check for
  # Edges that have a
  # Engines that call back to t
  # Report for all edges
  #   Count all that span domains (weight by total hits AND distinct fn_call_coupletf)
  def edge_stats
  end
  def initialize(options: nil)
    @options = options unless options.nil?
    reset
  end

  def reset
    @root_node = ChaosDetector::Node.new(root: true)
    @md5 = Digest::MD5.new
    @nodes = []
    @edges = []
    @frame_stack = []
    @frames_nopop = []
    @offset = 0

    @traversal_stats = GraphStats.new
  end

  def stack_depth
    @frame_stack.length
  end

  # @return Node matching given frame.  If already in @nodes,
  # that is returned, otherwise, a new one is created.
  def node_for_frame(frame:)
    node = @nodes.find do |n|
      n.domain_name == frame.domain_name &&
        n.mod_name == frame.mod_name &&
        n.mod_path == frame.mod_path
    end

    unless node
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
      sim_rank = ChaosDetector::Utils.with(current_frame.match?(f)) do |similarity|
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

  def count_depth
    -1
  end

  def count_breadth
    -1
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

  class GraphStats
    def initialize
      @push_count = 0
      @pop_count = 0
      @close_count = 0
      @match_unideal_count = 0
      @match_nonzero_count = 0
    end

    def record_open_action
      @push_count += 1
    end

    def record_close_action(frame_n, similarity)
      if frame_n.nil?
        @close_count += 1
      else
        @pop_count += 1
        @match_unideal_count += 1 unless ChaosDetector::StackFrame::VERY_SIMILAR.include?(similarity)
        @match_nonzero_count += 1 if frame_n > 0
      end
    end

    def to_s
      m << decorate(ROOT_NODE_NAME, clamp: :parens) if @is_root
      "Total: %s [+push -pop (-close)] +%d -%d(%d) unideal: %d >> stack-pos-off: %d" % [
        decorate(@push_count + @pop_count + @close_count, clamp: :bracket),
        @push_count,
        @pop_count,
        @close_count,
        @match_unideal_count,
        @match_nonzero_count
      ]
    end
  end
end