require_relative 'function_node'
require_relative 'domain_node'
require_relative 'module_node'

require 'chaos_detector/graph_theory/edge'
require 'chaos_detector/graph_theory/graph'
require 'chaos_detector/chaos_utils'

# Encapsulate and aggregates graphs for dependency tracking
#   * Function directed graph
#   * Module directed graph - derived from function graph
#   * Domain directed graph - derived from function graph
module ChaosDetector
  module ChaosGraphs
    class ChaosGraph
      NODE_TYPES = %i[function module domain].freeze
      STATES = %i[initialized inferred].freeze

      attr_reader :function_graph
      attr_reader :mod_rel_graph
      attr_reader :domain_nodes
      attr_reader :module_nodes

      attr_reader :domain_edges
      attr_reader :module_edges
      attr_reader :module_domain_edges
      attr_reader :domain_module_edges
      attr_reader :function_domain_edges
      attr_reader :domain_function_edges

      def initialize(function_graph, mod_rel_graph)
        @function_graph = function_graph
        @mod_rel_graph = mod_rel_graph
        @domain_nodes = nil
        @module_nodes = nil

        @domain_edges = nil
        @module_edges = nil
        @module_domain_edges = nil
        @domain_module_edges = nil
        @function_domain_edges = nil
        @domain_function_edges = nil
        # @module_graph = nil
        # @domain_graph = nil
      end

      def infer_all
        assert_state
        infer_domain_nodes
        infer_module_nodes
        infer_edges
        prepare_root_nodes
        self
        # @domain_graph = build_domain_graph(@domain_edges)
        # @module_graph = build_domain_graph(@module_edges)
      end

      # Lookup domain node by name:
      def domain_node_for(name:)
        domain_nodes.find{|node| node.name==domain_nodes}
      end

      ## Derive domain-level graph from function-based graph
      def build_domain_graph(edges)
        assert_state
        ChaosDetector::GraphTheory::Graph.new(root_node: root_node_domain, nodes: @domain_nodes, edges: edges)
      end

      ## Derive module-level graph from function-based graph
      def build_module_graph(edges: @module_edges)
        assert_state
        ChaosDetector::GraphTheory::Graph.new(root_node: root_node_module, nodes: @domain_nodes, edges: edges)
      end

    private

      def assert_state(state = nil)
        raise "function_graph.nodes isn't set!" unless function_graph&.nodes

        if state == :inferred
          raise "@domain_nodes isn't set; call #build" unless @domain_nodes
          raise "@module_nodes isn't set; call #build" unless @module_nodes
        end
      end

      def prepare_root_nodes
        assert_state(:inferred)
        ChaosUtils.with(root_node_function) do |fn_root_node|
          @function_graph.nodes.unshift(fn_root_node) unless @function_graph.nodes.include?(fn_root_node)
        end

        ChaosUtils.with(root_node_domain) do |domain_root_node|
          @domain_nodes.unshift(domain_root_node) unless @domain_nodes.include?(domain_root_node)
        end

        ChaosUtils.with(root_node_module) do |mod_root_node|
          @module_nodes.unshift(mod_root_node) unless @module_nodes.include?(mod_root_node)
        end
      end

      def root_node_function
        assert_state
        root_node = @function_graph.nodes.find(&:is_root)
        root_node || ChaosDetector::ChaosGraphs::FunctionNode.root_node
      end

      def root_node_domain
        assert_state(:inferred)
        root_node = @domain_nodes.find(&:is_root)
        root_node || ChaosDetector::ChaosGraphs::DomainNode.root_node
      end

      def root_node_module
        assert_state(:inferred)

        root_node = @module_nodes.find(&:is_root)
        root_node || ChaosDetector::ChaosGraphs::ModuleNode.root_node
      end

      def infer_domain_nodes
        assert_state

        @domain_nodes = @function_graph.nodes.group_by(&:domain_name).map do |dom_nm, fn_nodes|
          ChaosDetector::ChaosGraphs::DomainNode.new(domain_name: dom_nm, fn_node_count: fn_nodes.length)
        end
      end

      def infer_module_nodes
        assert_state

        grouped_nodes = @function_graph.nodes.group_by(&:mod_info_prime)
        mod_nodes = grouped_nodes.select do |mod_info, _fn_nodes|
          ChaosUtils.aught?(mod_info&.mod_name)
        end

        mod_nodes = mod_nodes.map do |mod_info, fn_nodes|
          node_fn = fn_nodes.first
          ChaosDetector::ChaosGraphs::ModuleNode.new(
            mod_name: mod_info.mod_name,
            mod_type: mod_info.mod_type,
            mod_path: mod_info.mod_path,
            domain_name: node_fn.domain_name,
            fn_node_count: fn_nodes.length
          )
        end

        mod_nodes.uniq!

        @mod_rel_graph.nodes.each do |rel_node|
          n = mod_nodes.index(rel_node)
          mod_nodes << rel_node if n.nil?
        end

        @module_nodes = mod_nodes.uniq
      end

      def infer_edges
        assert_state

        edges = @function_graph.edges
        @domain_edges = group_edges_by(edges, :domain, :domain)
        mod_edges = group_edges_by(edges, :module, :module)

        @mod_rel_graph.edges.each do |rel_edge|
          n = mod_edges.index(rel_edge)
          if n.nil?
            mod_edges << rel_edge
          else
            mod_edges[n].edge_type = rel_edge.edge_type
          end
        end

        @module_edges = mod_edges
      end

      def group_edges_by(edges, src, dep)
        assert_state
        raise ArgumentError, 'edges argument required' unless edges

        # log("GROUPING EDGES by #{src} and #{dep}")

        groupedges = edges.group_by do |e|
          [
            node_group_prop(e.src_node, node_type: src),
            node_group_prop(e.dep_node, node_type: dep)
          ]
        end

        # valid_edges = groupedges.select do |src_dep_pair, g_edges|
        #   src_dep_pair.all?
        # end

        groupedges.filter_map do |src_dep_pair, g_edges|
          raise 'Pair should have two exactly items.' unless src_dep_pair.length == 2

          # log("Looking up pair: #{src_dep_pair.inspect}")
          edge_src_node = lookup_node_by(node_type: src, node_info: src_dep_pair.first)
          edge_dep_node = lookup_node_by(node_type: dep, node_info: src_dep_pair.last)

          # log("Creating #{src_dep_pair.first.class} edge with #{ChaosUtils.decorate_pair(edge_src_node, edge_dep_node)}")
          (edge_src_node != edge_dep_node) && ChaosDetector::GraphTheory::Edge.new(edge_src_node, edge_dep_node, reduce_cnt: g_edges.length)
        end
      end

      def node_group_prop(node, node_type:)
        unless NODE_TYPES.include? node_type
          raise format('node_type should be one of symbols in %s, actual value: %s (%s)', NODE_TYPES.inspect, ChaosUtils.decorate(node_type), ChaosUtils.decorate(node_type.class))
        end

        case node_type
        when :function
          node.to_info
        when :module
          node.mod_info_prime
        when :domain
          node.domain_name
        end
      end

      def lookup_node_by(node_type:, node_info:)
        assert_state

        # It is already a node:
        return node_info if node_info.is_a? ChaosDetector::GraphTheory::Node

        case node_type
        when :function
          # Look up by FnInfo
          n = node_info && @function_graph.nodes.index(node_info)
          n.nil? ? root_node_function : @function_graph.nodes[n]
        when :module
          # Look up my module info
          n = node_info && @module_nodes.index(node_info)
          n.nil? ? root_node_module : @module_nodes[n]
        when :domain
          # Look up by Domain name
          unless (node_info.is_a?(String) || node_info.is_a?(Symbol))
            log("NodeInfo is something other than info or string type: class: (#{node_info.class}) = #{node_info.inspect}")
          end

          name = node_info.to_s
          @domain_nodes.find { |n| n.name == name } || root_node_domain
        else
          raise "node_type should be one of #{NODE_TYPES.inspect}, actual value: #{ChaosUtils.decorate(node_type)}"
        end
      end

      def log(msg)
        ChaosUtils.log_msg(msg, subject: 'ChaosGraph')
      end
    end
  end
end
