require 'chaos_detector/options'
require 'chaos_detector/navigator'
require 'chaos_detector/stacker/frame'
require 'chaos_detector/graph_theory/appraiser'
require 'chaos_detector/graph_theory/graph'
require 'chaos_detector/graphing/directed'
require 'chaos_detector/chaos_graphs/chaos_graph'
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

      def playback(row_range: nil)
        fn_graph, mod_graph = @navigator.playback(row_range: row_range)
        @chaos_graph = ChaosDetector::ChaosGraphs::ChaosGraph.new(fn_graph, mod_graph)
        @chaos_graph.infer_all
      end

      GRAPH_TYPE_ATTRS = {
        domain: {
          ratio: 'auto',
          size: '8, 8',
        },
        function: {

        },
        module: {

        },
      }

      def render_dep_graph(graph_type, graph:nil, as_cluster: false, domains: false, name: nil)
        g, _appraiser = chaos_graph.graph_data_for(graph_type: graph_type)
        rgraph = graph ? graph : g
        graph_name = name ? name : "#{graph_type}-dep"

        graph_attrs = GRAPH_TYPE_ATTRS[graph_type]

        dgraph = if domains #&& graph_type != :cluster
          build_domain_dgraph(graph_name, rgraph.nodes, rgraph.edges, as_cluster: as_cluster, graph_attrs: graph_attrs)
        else
          build_dgraph(graph_name, rgraph.nodes, rgraph.edges, as_cluster: as_cluster, graph_attrs: graph_attrs)
        end

        dgraph.rendered_path
      end

      def render_domain_dep(graph_name: 'domain-dep')
        graph_attrs = {
          ratio: 'auto',
          size: '8, 8',
        }
        dgraph = build_dgraph(graph_name, chaos_graph.domain_nodes, chaos_graph.domain_edges, as_cluster: true, graph_attrs: graph_attrs)
        dgraph.rendered_path
      end

      def render_fn_dep(graph_name: 'fn-dep', function_graph: nil, domains: false)
        fn_graph = function_graph ? function_graph : chaos_graph.function_graph
        nodes = fn_graph.nodes
        edges = fn_graph.edges

        dgraph = if domains
          build_domain_dgraph(graph_name, nodes, edges, as_cluster: as_cluster)
        else
          build_dgraph(graph_name, nodes, edges)
        end

        dgraph.rendered_path
      end

      def render_mod_dep(graph_name: 'module-dep', module_graph: nil, domains: false)
        graph_attrs = {
          # ratio: 'auto',
          # size: '50, 50',
          # newrank: 'false',
          # ranksep: '1.0',
          splines: 'ortho',
        }

        mod_graph = module_graph ? module_graph : chaos_graph.module_graph
        nodes = mod_graph.nodes
        edges = mod_graph.edges

        dgraph = if domains
          build_domain_dgraph(graph_name, nodes, edges, graph_attrs: graph_attrs)
        else
          build_dgraph(graph_name, nodes, edges, graph_attrs: graph_attrs)
        end

        dgraph.rendered_path
      end

      private

        def build_dgraph(label, nodes, edges, as_cluster: false, render: true, graph_attrs: nil)
          # nodes.each do |n|
          #   p("#{label} Nodes: #{ChaosUtils.decorate(n.title)}")
          # end

          # edges.each do |e|
          #   p("#{label} Edges: #{ChaosUtils.decorate(e.src_node.title)} -> #{ChaosUtils.decorate(e.dep_node.title)}")
          # end

          dgraph = ChaosDetector::Graphing::Directed.new(render_folder: @render_folder)
          dgraph.create_directed_graph(label, graph_attrs: graph_attrs)
          dgraph.append_nodes(nodes, as_cluster: as_cluster)
          dgraph.add_edges(edges)
          dgraph.render_graph if render
          dgraph
        end

        def build_domain_dgraph(graph_name, nodes, edges, render: true, graph_attrs: nil)
          # Add domains as cluster/subgraph nodes:
          domain_nodes = nodes.map{|node| chaos_graph.domain_node_for(name: node.domain_name) }
          dgraph = build_dgraph(graph_name, domain_nodes, [], as_cluster: true, render: false, graph_attrs: graph_attrs)

          # Add nodes to domains:
          dgraph.append_nodes(nodes) do |node|
            chaos_graph.domain_node_for(name: node.domain_name)
          end
          dgraph.add_edges(edges)
          dgraph.render_graph if render
          dgraph
          # dgraph.rendered_path

          # fn_nodes = chaos_graph.function_graph.nodes.group_by(&:domain_name)
          # fn_nodes.map do |dom_nm, fn_nodes|
          #   dom_node = ChaosUtils.aught?(dom_nm) && chaos_graph.domain_node_for(name: dom_nm)
          #   dgraph.add_node_to_parent(fn_node, dom_node)
          # end
        end

    end
  end
end
