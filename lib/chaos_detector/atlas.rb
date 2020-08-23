require 'digest'
require 'chaos_detector/edge'
require 'chaos_detector/node'
require 'chaos_detector/options'
require 'chaos_detector/stack_frame'
require 'chaos_detector/utils'

# TODO: add traversal types to find depth, coupling in various ways (directory/package/namespace):
module ChaosDetector
class Atlas
  extend ChaosDetector::Utils::ChaosAttr

  chaos_attr (:options) { ChaosDetector::Options.new }

  FULL_TOLERANCE = 6
  PARTIAL_TOLERANCE = 3
  BASE_TOLERANCE = 1

  INDENT = " ".freeze
  ROOT_NODE_NAME = "root".freeze

  chaos_attr :nodes, []
  chaos_attr :edges, []
  chaos_attr :frame_stack, []
  chaos_attr :offset, 0
  chaos_attr :frames_nopop, []
  chaos_attr :graph_stats

  def initialize(options: nil)
    @options = options unless options.nil?
    reset
  end

  def reset
    @root_node = ChaosDetector::Node.new(mod_name:ROOT_NODE_NAME, path:"", domain_name:nil)
    @md5 = Digest::MD5.new
    @nodes = []
    @edges = []
    @frame_stack = []
    @frames_nopop = []

    @offset = 0

    @graph_stats = GraphStats.new
    init_status_csv
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

  def stack_match(current_frame)
    raise ArgumentError("Current Frame is required") if current_frame.nil?

    # Ranking to index:
    best_index = nil
    best_rank = -1
    best_sim = nil
    window = @offset + FULL_TOLERANCE

    @frame_stack[0..window].each_with_index do |f, n|
      sim_rank = ChaosDetector::Utils.with(current_frame.match?(f)) do |similarity|
        if ChaosDetector::StackFrame::VERY_SIMILAR.include?(similarity)
          [similarity, FULL_TOLERANCE]
        elsif similarity==ChaosDetector::StackFrame::SimilarityRating::Partial
          [similarity, PARTIAL_TOLERANCE]
        elsif similarity==ChaosDetector::StackFrame::SimilarityRating::Base
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

    #   buffy = []
    #   # Due to the dynamic nature of ruby; meta-programming, method_missing, etc
    #   # matching with tolerance:
    #   @frame_stack[1..-1].each_with_index do |f, i|
    #     msg = "#{i}"
    #     ChaosDetector::Utils.with(current_frame.match?(f)) do |match|
    #       match_candidates[i] = match
    #       msg << ": #{match}"
    #       msg << " [#{f.to_s}]"
    #       buffy << msg
    #     end
    #   end

    #   @graph_stats.no_matches += 1

    #   log_status(action: "NO EAASY MATCH for (#{current_frame}) ", details: buffy)

    #   # Find best match
    #   # It isn't always an easy apples-apples when looking for
    #   # Due to the dynamic nature of ruby; meta-programming, method_missing, etc
    #   # todeo: PARTIAL MATCH allow
    #   # if frame.domain_name == frame.domain_name
    #   # @domain_name == other.domain_name &&
    #   # @mod_name == other.mod_name &&
    #   # @path == other.path &&
    #   # @fn_name == other.fn_name
    #   # buffy = match_candidates.entries.map{|k,v| "#{k}: #{v}"}

    #   # mf = ChaosDetector::Utils.with(match_candidates.entries.first) do |position, rating|
    #   #   @graph_stats.unideal_matches += 1
    #   #   log_status(action: "PARTIAL CANDIDATE(#{rating}) [#{position}] frames back (#{current_frame})", details: buffy)
    #   #   @graph_stats.increment_rating(rating)
    #   # end

    #   # if mf.nil?
    #   #   log_status(action: "NO CANDIDATE for (#{current_frame}) ")
    #   #   @graph_stats.no_matches += 1
    #   # end
    # end

    # matching_frame || current_frame
  #   matching_frame
  # end

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

  def log_path
    File.join(options.log_root_path, options.atlas_log_path)
  end

  def init_status_csv()
    csv_status = %w{action offset stack_length node_count edge_count}
    atlas_path = log_path
    File.write(atlas_path, csv_status, File.size(atlas_path), mode: 'w')
  end

  def write_csv_status(action)
    csv_status = [action, offset, @frame_stack.length, @nodes.length, @edges.length].join(', ')
    atlas_path = log_path
    File.write(atlas_path, csv_status, File.size(atlas_path), mode: 'a')
  end

  def log_status(action:, indent: '', details: nil)
    write_csv_status(action)
    indent = INDENT * [@frame_stack.length, 25].min
    # exit(false) if stack_len > 25

    puts "#{indent}[#{action}] Stack offset: #{offset} -> Stack depth: #{@frame_stack.length}(#{@graph_stats}) / Node count: #{nodes.length} "
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

    @frame_stack.unshift(frame)
    @graph_stats.open_count += 1
    log_status(action: "#OPEN(#{frame})")

  end

  def close_frame(frame:)
    buffy=[]

    # log_status(action: "#<CLOSE(#{frame})")
    # indent = INDENT * (@frame_stack.length + 1)

    frame_n, similarity = stack_match(frame)

    if frame_n.nil?
      buffy << "No frame found: #{frame}"
      buffy.concat(@frame_stack.first(50).map{|f| "  <- #{f}"})
    else
      # if stack_frame.ma != frame
      #   buffy << "Pop Mismatch: #{frame} <> #{stack_frame}"
      #   # buffy.concat(@frame_stack.first(50).reverse.map{|f| "  -> #{f}"})
      # end
      # buffy << "POPPING from frame stack: #{frame}"
      @frame_stack.delete_at(frame_n)
    end

    # indent.chomp!(INDENT)
    @graph_stats.close_count += 1
    log_status(action: "#>>>CLOSE@#{frame_n} <<#{similarity}>> (#{frame})", details: buffy)
  end

  class GraphStats
    attr_accessor :open_count
    attr_accessor :close_count

    attr_accessor :perfect_matches
    attr_accessor :ideal_matches
    attr_accessor :unideal_matches
    attr_accessor :no_matches

    attr_accessor :rating_counts
    # attr_accessor :partial_matches
    # attr_accessor :exact_matches
    # attr_accessor :full_matches

    def initialize
      @open_count = 0
      @close_count = 0

      @perfect_matches = 0
      @ideal_matches = 0
      @unideal_matches = 0
      @no_matches = 0

      @rating_counts = {}
    end

    def increment_rating(rating)
      rating_counts[rating] = rating_counts.fetch(rating, 0) + 1
    end

    def to_s
      " +#{@open_count} -#{@close_count} =(#{@open_count - @close_count}) ->[**#{@perfect_matches} / *#{@ideal_matches} / ^#{@unideal_matches} / !#{@no_matches}]"
    end
  end


end
end