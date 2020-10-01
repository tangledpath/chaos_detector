require 'chaos_detector/navigator'
require 'chaos_detector/stacker/frame'
require 'chaos_detector/graphing/directed'
require 'chaos_detector/chaos_graphs/chaos_graph'
require 'chaos_detector/graph_theory/graph'
require 'chaos_detector/options'
require 'chaos_detector/utils/str_util'
require 'chaos_detector/chaos_utils'

module ChaosDetector
  module Graphing
    ### Top-level Chaos-detection graphing and rendering
    class Graphs
      attr_reader :navigator
      attr_reader :chaos_graph

      def initialize(options: nil)
        @options = options || ChaosDetector::Options.new
        @render_folder = @options.path_with_root(key: :graph_render_folder)
        # @render_folder = @options.graph_render_folder
        ChaosDetector::Utils::FSUtil.ensure_dirpath(@render_folder)
        @navigator = ChaosDetector::Navigator.new(options: @options)
      end

      def playback
        fn_graph, mod_graph = @navigator.playback
        @chaos_graph = ChaosDetector::ChaosGraphs::ChaosGraph.new(fn_graph, mod_graph)
        @chaos_graph.infer_all
      end

      def render_domain_dep(graph_name: 'domain-dep')
        dgraph=build_dgraph(graph_name, chaos_graph.domain_nodes, chaos_graph.domain_edges, as_cluster: true)
        dgraph.rendered_path
      end

      def render_fn_dep(graph_name: 'fn-dep', domains: false)
        nodes = chaos_graph.function_graph.nodes
        edges = chaos_graph.function_graph.edges

        dgraph = if domains
          build_domain_dgraph(graph_name, nodes, edges)
        else
          build_dgraph(graph_name, nodes, edges)
        end

        dgraph.rendered_path
      end

      def render_mod_dep(graph_name: 'module-dep', domains: false)
        nodes = chaos_graph.module_nodes
        edges = chaos_graph.module_edges

        dgraph = if domains
          build_domain_dgraph(graph_name, nodes, edges)
        else
          build_dgraph(graph_name, nodes, edges)
        end

        dgraph.rendered_path
      end

      def build_dgraph(label, nodes, edges, as_cluster: false)
        # nodes.each do |n|
        #   p("#{label} Nodes: #{ChaosUtils.decorate(n.label)}")
        # end

        # edges.each do |e|
        #   p("#{label} Edges: #{ChaosUtils.decorate(e.src_node.label)} -> #{ChaosUtils.decorate(e.dep_node.label)}")
        # end

        dgraph = ChaosDetector::Graphing::Directed.new(render_folder: @render_folder)
        dgraph.create_directed_graph(label)
        dgraph.append_nodes(nodes, as_cluster: as_cluster)
        dgraph.add_edges(edges)
        dgraph.render_graph
      end

      def build_domain_dgraph(graph_name, nodes, edges)
        # Add domains as cluster/subgraph nodes:
        dgraph = build_dgraph(graph_name, chaos_graph.domain_nodes, chaos_graph.domain_edges, as_cluster: true)

        # Add nodes to domains:
        dgraph.append_nodes(nodes) do |node|
          # find parent node
          ChaosUtils.with(node.domain_name) do |dom_nm|
            ChaosUtils.aught?(dom_nm) ? chaos_graph.domain_node_for(dom_nm) : nil
          end
        end
        dgraph.add_edges(edges)
        dgraph.render_graph
        # dgraph.rendered_path

        # fn_nodes = chaos_graph.function_graph.nodes.group_by(&:domain_name)
        # fn_nodes.map do |dom_nm, fn_nodes|
        #   dom_node = ChaosUtils.aught?(dom_nm) && chaos_graph.domain_node_for(dom_nm)
        #   dgraph.add_node_to_parent(fn_node, dom_node)
        # end
      end

    end
  end
end
