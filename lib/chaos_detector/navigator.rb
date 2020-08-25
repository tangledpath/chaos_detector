require 'pathname'
require_relative 'options'
require_relative 'stacker/mod_info'
require_relative 'chaos_graphs/module_node'
require_relative 'stacker/frame'
require_relative 'walkman'
require 'chaos_detector/chaos_utils'

# The main interface for intercepting tracepoints,
# and converting them into recordable and playable
# stack/trace frames

module ChaosDetector
  class Navigator
    REGEX_MODULE_UNDECORATE = /#<(Class:)?([a-zA-Z\:]*)(.*)>/.freeze
    DEFAULT_GROUP="default".freeze
    FRAME_ACTIONS = [:return]#, :return, :class, :end]

    attr_reader :options
    attr_reader :domain_hash
    attr_reader :walkman

    attr_reader :nodes
    attr_reader :edges

    def initialize(options:)
      raise ArgumentError, "#initialize requires options" if options.nil?
      @options = options
      apply_options
    end

    ### Playback of walkman CSV file:
    def playback()
      log("Chaos playing through navigator.  Expected lines: ", object: @walkman.count)
      @nodes = Set.new
      @edges_call = Set.new
      @edges_ret = Set.new

      @walkman.playback do |rownum, frame|
        perform_node_action(frame)
      end
      log("Found nodes.", object: @nodes.length)

      @walkman.playback do |rownum, frame|
        perform_edge_action(frame)
      end

      @graph = ChaosDetector::GraphTheory::Graph.new(
        root_node: ChaosDetector::ChaosGraphs::FunctionNode.root_node(force_new: true),
        nodes: @nodes.to_a,
        edges: merge_edges.to_a
      )
    end

    private

      def apply_options
        @walkman = ChaosDetector::Walkman.new(options: @options)
        @domain_hash = {}
        @options.path_domain_hash && options.path_domain_hash.each do |path, group|
          dpath = Pathname.new(path.to_s).cleanpath.to_s
          @domain_hash[dpath] = group
        end
      end

      def merge_edges
        c = Set.new(@edges_call)
        r = Set.new(@edges_ret)

        raise 'Call Edges should be Set' unless c.length == @edges_call.length
        raise 'Ret Edges should be Set' unless r.length == @edges_ret.length

        raise 'Call Edges should be unique' unless @edges_call.uniq.length == @edges_call.length
        raise 'Call Edges should be unique' unless @edges_ret.uniq.length == @edges_ret.length

        # log("FFF", object: (@edges_call + @edges_ret).uniq.length)
        # log("GGG", object: (c + r).uniq.length)
        log("Unique edges in call (n/total)", object: [(c - r).length, c.length])
        log("Unique edges in return (n/total)", object: [(r - c).length, r.length])

        # @edges_call.each do |e|
        #   log("edges_call", object: e)
        # end

        # @edges_ret.each do |e|
        #   log("edges_ret ", object: e)
        # end

        c.union(r)
      end

      def node_for(fn_info)
        return nil unless fn_info&.fn_name

        @nodes.find do |n|
          n.fn_name == fn_info.fn_name &&
          n.fn_path == fn_info.fn_path
        end
      end

      # @return Node matching given frame or create a new one.
      def node_for_frame(frame)
        # log("Calling node_for_frame", object: frame)
        node = node_for(frame.fn_info)

        if node.nil? && frame.event == 'call'
          node = @nodes << ChaosDetector::ChaosGraphs::FunctionNode.new(
            fn_name: frame.fn_info.fn_name,
            fn_path: frame.fn_info.fn_path,
            fn_line: frame.fn_info.fn_line,
            domain_name: domain_from_path(local_path: frame.fn_info.fn_path),
            mod_info: frame.mod_info
          )
        end

        node
      end

      def edge_for_nodes(src_node, dep_node, event:)
        edges = event == 'return' ? @edges_ret : @edges_call
        edge = edges.find do |e|
          e.src_node == src_node && e.dep_node == dep_node
        end

        if edge.nil?
          edge=edges << ChaosDetector::GraphTheory::Edge.new(src_node, dep_node)
        end
        edge

      end

      def perform_node_action(frame)
        node = node_for_frame(frame)

        ChaosUtils.with(node && frame.event == 'return' && frame.fn_info.fn_line) do |fn_line|
          if !node.fn_line_end.nil? && node.fn_line_end != fn_line
            puts "WTF: (node.fn_line_end) != (fn_line) (#{fn_line}) != (#{fn_line})"
          end
          node.fn_line_end = [fn_line, node.fn_line_end.to_i].max
        end
      end

      def perform_edge_action(frame)
        return unless frame.fn_info #&& frame.caller_fn_info

        dest_node = node_for(frame.fn_info)
        raise "Couldn't find destination node" if dest_node.nil?
        caller_node = node_for(frame.caller_fn_info)
        if caller_node.nil?
          caller_node = ChaosDetector::ChaosGraphs::FunctionNode.root_node
          raise "Caller node is required (falls back to root)." if caller_node.nil?
          log("Adding edge to root!")
          @nodes << caller_node
         end

        edge_for_nodes(caller_node, dest_node, event: frame.event)
      end

      def domain_from_path(local_path:)
        key = domain_hash.keys.find{|k| local_path.start_with?(k)}
        key ? domain_hash[key] : DEFAULT_GROUP
      end

      def log(msg, **opts)
        ChaosUtils::log_msg(msg, subject: "Navigator", **opts)
      end

  end
end