require 'digest'
require 'chaos_detector/edge'
require 'chaos_detector/node'
require 'chaos_detector/stack_frame'
require 'chaos_detector/utils'

# TODO: add traversal types to find depth, coupling in various ways (directory/package/namespace):
class ChaosDetector::Graph
  INDENT = " ".freeze
  ROOT_NODE_NAME = "root".freeze

  attr_reader :nodes
  attr_reader :edges
  attr_reader :frame_stack
  attr_reader :frames_nopop
  attr_reader :nodes_skip_pop

  def initialize
    @md5 = Digest::MD5.new
    @root_node = ChaosDetector::Node.new(mod_name:ROOT_NODE_NAME, path:"", domain_name:nil)
    @nodes = []
    @edges = []
    @frame_stack = []
    @frames_nopop = []
    @nodes_skip_pop = []
  end

  def stack_depth
    frame_stack.length
  end

  # @return Node matching given frame.  If already in @nodes,
  # that is returned, otherwise, a new one is created.
  def node_for_frame(frame:)
    node = @nodes.find do |n|
      n.domain_name == frame.domain_name &&
        n.mod_name == frame.mod_name &&
        n.path == frame.path
    end

    unless node
      @nodes << node=ChaosDetector::Node.new(domain_name: frame.domain_name, mod_name: frame.mod_name, path: frame.path)
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

  def stack_match(current_frame:)
    raise ArgumentError("Current Frame is required") if current_frame.nil?

    prior_frame = @frame_stack.last
    if prior_frame.nil?
      log_status(action: "Empty frame stack while matching: #{current_frame}")
      return nil
    elsif prior_frame == current_frame
      # Ideal case:
      return prior_frame
    end


    matching_frame = nil
    match_candidates = {}

    # Due to the dynamic nature of ruby; meta-programming, method_missing, etc
    # todeo: PARTIAL MATCH allow
    @frame_stack.each_with_index do |f, i|
      # Add with thingy:
      ChaosDetector::Utils.with(frame.match(f)) do |match|
        match_candidates[i] = match
      end
    end

    # Find best match
    # It isn't always an easy apples-apples when looking for
    # Due to the dynamic nature of ruby; meta-programming, method_missing, etc
    # todeo: PARTIAL MATCH allow
    # if frame.domain_name == frame.domain_name
    # @domain_name == other.domain_name &&
    # @mod_name == other.mod_name &&
    # @path == other.path &&
    # @fn_name == other.fn_name
    matching_frame = ChaosDetector::Utils.with(match_candidates.entries.first) do |position, rating|
      if position.zero?
        log_status(action: "CLOSE MATCH(#{rating}) AT END(#{frame})")
      else
        log_status(action: "PARTIAL MATCH(#{rating}) [#{position}] frames back (#{frame})")

        # TODO: Log more previous frames:
      end
    end

    if matching_frame.nil?
      log_status(action: "NO MATCH for (#{frame}) ")
    end

    # matching_frame || current_frame
    matching_frame
  end

  # def make_key(path:, mod_name:, domain_name:, fn_name:, line_num:)
  #   @md5.reset
  #   @md5 << path if (path && !path.empty?)
  #   @md5 << mod_name if (mod_name || !mod_name.empty?)
  #   @md5 << domain_name.to_s if (domain_name || !domain_name.empty?)
  #   @md5 << fn_name if (fn_name || !fn_name.empty?)
  #   @md5 << line_num if line_num
  #   @md5.hexdigest
  # end

  def count_depth
    -1
  end

  def count_breadth
    -1
  end

  def log_status(action:, indent: '', details: nil)
    # stack_len = @frame_stack.length

    indent = INDENT * [@frame_stack.length, 25].min
    # exit(false) if stack_len > 25


    puts "#{indent}[#{action}] Stack depth: #{@frame_stack.length} / Node count: #{nodes.length}"
    if details
      j = "\n#{indent}  "
      puts j + details.join("\n#{indent}  ")
      puts
    end
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

    log_status(action: "#OPEN(#{frame})")
    @frame_stack.push(frame)
  end

  def close_frame(frame:)
    buffy=[]

    # log_status(action: "#<CLOSE(#{frame})")
    # indent = INDENT * (@frame_stack.length + 1)

    stack_frame = stack_match(current_frame:frame)
    if stack_frame
      # if stack_frame.ma != frame
      #   buffy << "Pop Mismatch: #{frame} <> #{stack_frame}"
      #   # buffy.concat(@frame_stack.last(50).reverse.map{|f| "  -> #{f}"})
      # end
      buffy << "POPPING from frame stack: #{frame}"
      @frame_stack.delete(frame)
    else
      buffy << "FRAME NOT FOUND(#{@frames_nopop.length}/#{@frames_nopop.uniq.length})"
      # @frames_nopop << frame
      # buffy << "FRAME NOT FOUND(#{@frames_nopop.length}/#{@frames_nopop.uniq.length})"
      # buffy.concat(@frame_stack.last(50).reverse.map{|f| "  -> #{f}"})
    end

    # indent.chomp!(INDENT)
    log_status(action: "#>>>CLOSE(#{frame})", details: buffy)
  end
end
