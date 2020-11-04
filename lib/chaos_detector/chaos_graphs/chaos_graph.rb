require_relative 'function_node'
require_relative 'domain_node'
require_relative 'module_node'

require 'chaos_detector/chaos_utils'
require 'chaos_detector/graph_theory/appraiser'
require 'chaos_detector/graph_theory/edge'
require 'chaos_detector/graph_theory/graph'
require 'chaos_detector/graph_theory/node'
require 'chaos_detector/graph_theory/reduction'

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

      attr_reader :domain_appraisal
      attr_reader :function_appraisal
      attr_reader :module_appraisal
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
      end

      def infer_all
        assert_state
        infer_module_nodes
        infer_domain_nodes
        prepare_root_nodes

        # Now infer all edges:
        infer_edges

        # Graph theory appraisal
        appraise_all
        self
        # @domain_graph = build_domain_graph(@domain_edges)
        # @module_graph = build_domain_graph(@module_edges)
      end

      # ChaosDetector::ChaosGraphs::ChaosGraph.NODE_TYPES
      def derive_graph(graph_type:, sort_col: :total_couplings, include_root: true, sort: :desc, top: nil)
        sortcol = sort_col || :total_couplings
        graph, appraisal = graph_data_for(graph_type: graph_type)

        nodes = graph.nodes(include_root: false)
        # nodes.filter!{ |node| yield(node) } if block_given?

        # Use appraisal metrics for sorting:
        node_metrics = nodes.map{|node| appraisal.metrics_for(node: node)}
        n_sort = node_metrics.map{|m| m.send(sortcol)}.map.with_index.sort.map(&:last)
        n_sort.reverse! if sort == :desc

        # Limit:
        if top
          ChaosUtils.with(top.to_i) do |t|
            n_sort = n_sort.take(t) if t.positive?
          end
        end


        gnodes = n_sort.map{|i| nodes[i].clone }

        # gnodes = new_nodes.map(&:clone)
        gedges = graph.edges.filter_map do |edge|
          src_node = gnodes.find{ |node| node == edge.src_node }
          dep_node = gnodes.find{ |node| node == edge.dep_node }
          if src_node && dep_node
            edge.dup.tap do |gedge|
              gedge.src_node = src_node
              gedge.dep_node = dep_node
            end
          end
        end

        ChaosDetector::GraphTheory::Graph.new(
          root_node: include_root ? gnodes.find(&:is_root)&.dup : nil,
          nodes: gnodes,
          edges: gedges
        )
      end

      def domain_graph
        assert_state(:inferred)
        @domain_graph ||= build_domain_graph(edges: @domain_edges)
      end

      def module_graph
        assert_state(:inferred)
        @module_graph ||= build_module_graph(edges: @module_edges)
      end

      # Lookup domain node by name:
      def domain_node_for(name:)
        # domain_nodes.find(->{root_node_domain}){|node| node.name.to_s == name.to_s}
        domain_nodes.find(->{root_node_domain}){|node| node.name.to_s == name.to_s}
      end

      ## Derive domain-level graph from function-based graph
      def build_domain_graph(edges: @domain_edes)
        assert_state
        ChaosDetector::GraphTheory::Graph.new(root_node: root_node_domain, nodes: @domain_nodes, edges: edges)
      end

      ## Derive module-level graph from function-based graph
      def build_module_graph(edges: @module_edges)
        assert_state
        ChaosDetector::GraphTheory::Graph.new(root_node: root_node_module, nodes: @module_nodes, edges: edges)
      end

      ## Return [graph, appraisal] for given type:
      def graph_data_for(graph_type:)
        assert_state(:inferred)

        case graph_type
          when :function
            [function_graph, function_appraisal]
          when :module
            [module_graph, module_appraisal]
          when :domain
            [domain_graph, domain_appraisal]
          else
            raise "graph_type should be one of #{NODE_TYPES.inspect}, actual value: #{ChaosUtils.decorate(graph_type)}"
          end
      end

      # Use Graph theory to appraise given graph:
      def appraise_graph(graph, sort_col: :total_couplings, sort_desc: true, top: nil)
        appraiser = ChaosDetector::GraphTheory::Appraiser.new(graph)
        appraiser.appraise
        appraiser
      end


    private

      # Graph theory appraisal
      def appraise_all
        log("Appraising graphs")
        @domain_appraisal = appraise_graph(domain_graph)
        @module_appraisal = appraise_graph(module_graph)
        @function_appraisal = appraise_graph(function_graph)
      end

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

      def infer_module_nodes
        assert_state

        grouped_nodes = @function_graph.nodes.group_by(&:mod_info_prime)

        # mod_nodes = grouped_nodes.select do |mod_info, _fn_nodes|
        #   ChaosUtils.aught?(mod_info&.mod_name)
        # end

        mod_nodes = grouped_nodes.filter_map do |mod_info, fn_nodes|
          next unless ChaosUtils.aught?(mod_info&.mod_name)

          node_fn = fn_nodes.first

          fn_reductions = fn_nodes.map(&:reduction)

          mod_reduction = ChaosDetector::GraphTheory::Reduction.combine_all(fn_reductions)
          # puts ("mod_reduction: %s" % mod_reduction.inspect)

          ChaosDetector::ChaosGraphs::ModuleNode.new(
            mod_name: mod_info.mod_name,
            mod_type: mod_info.mod_type,
            mod_path: mod_info.mod_path,
            domain_name: node_fn.domain_name,
            reduction: mod_reduction
          )
        end

        mod_nodes.uniq!

        @mod_rel_graph.nodes.each do |rel_node|
          n = mod_nodes.index(rel_node)
          mod_nodes << rel_node if n.nil?
        end

        @module_nodes = mod_nodes.uniq
      end

      def infer_domain_nodes
        assert_state

        @domain_nodes = @module_nodes.group_by(&:domain_name).map do |dom_nm, mod_nodes|
          mod_reductions = mod_nodes.map(&:reduction)
          dom_reduction = ChaosDetector::GraphTheory::Reduction.combine_all(mod_reductions)
          ChaosDetector::ChaosGraphs::DomainNode.new(
            domain_name: dom_nm,
            reduction: dom_reduction,
            is_root: dom_nm==ChaosDetector::GraphTheory::Node::ROOT_NODE_NAME || !ChaosUtils.aught?(dom_nm)
          )
        end
      end

      def infer_edges
        assert_state

        fn_edges = @function_graph.edges
        mod_edges = group_edges_by(fn_edges, :module, :module).concat(@mod_rel_graph.edges)
        check_edges("mod_edges", mod_edges)

        dom_edges = group_edges_by(mod_edges, :domain, :domain)
        check_edges("dom_edges", dom_edges)

        @domain_edges = reduce_edges(dom_edges)
        check_edges("@domain_edges", @domain_edges)

        @module_edges = reduce_edges(mod_edges)
        check_edges("@module_edges", @module_edges)
      end

      def check_edges(name, edges)
        return
        edges.each do |edge|
          puts("#{name} EDGE: #{edge.class} / #{edge.reduction.class} / #{edge}")
        end
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
          if (edge_src_node != edge_dep_node)
            ChaosDetector::GraphTheory::Edge.new(
              edge_src_node,
              edge_dep_node,
              reduction: ChaosDetector::GraphTheory::Reduction.new(
                reduction_count: g_edges.count,
                reduction_sum: g_edges.reduce(0) do |sum, e|
                  sum + (e.reduction&.reduction_count || 1)
                end
              )
            )
          end
        end
      end

      def reduce_edges(edges)
        edges.reduce(Set.new) do |memo, obj|
          existing = memo.find{|m| obj==m}
          if existing
            existing.merge!(obj)
          else
            memo << obj
          end
          memo
        end.to_a
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
          # Look up by module info
          n = node_info && @module_nodes.index(node_info)
          n.nil? ? root_node_module : @module_nodes[n]
        when :domain
          # Look up by Domain name
          unless (node_info.nil? || node_info.is_a?(String) || node_info.is_a?(Symbol))
            log("NodeInfo is something other than info or string type: class: (#{node_info.class}) = #{node_info.inspect}")
          end

          domain_node_for(name: node_info.to_s) || root_node_domain
        else
          raise "node_type should be one of #{NODE_TYPES.inspect}, actual value: #{ChaosUtils.decorate(node_type)}"
        end
      end

      def log(msg, **opts)
        ChaosUtils.log_msg(msg, subject: 'ChaosGraph', **opts)
      end
    end
  end
end
