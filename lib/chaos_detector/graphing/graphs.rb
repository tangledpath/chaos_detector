require 'chaos_detector/navigator'
require 'chaos_detector/stacker/frame'
require 'chaos_detector/graphing/directed'
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
        @render_path = @options.path_with_root(:graph_render_folder)
        ChaosDetector::Utils::FSUtil.ensure_dirpath(@render_path)
        @navigator = ChaosDetector::Navigator.new(options: @options)
      end

      def playback
        fn_graph, mod_graph = @navigator.playback
        @chaos_graph = ChaosDetector::ChaosGraphs::ChaosGraph.new(fn_graph, mod_graph)
        @chaos_graph.infer_all
      end

      def render_fn_dep(graph_name='fn-dep')
        fn_graph = chaos_graph.function_graph
        build_dgraph(graph_name, fn_graph.nodes, fn_graph.edges)
      end

      def render_mod_dep(graph_name='module-dep')
        build_dgraph(graph_name, chaos_graph.module_nodes, chaos_graph.module_edges)
      end

      def build_dgraph(label, nodes, edges)
        # nodes.each do |n|
        #   p("#{label} Nodes: #{ChaosUtils.decorate(n.label)}")
        # end

        # edges.each do |e|
        #   p("#{label} Edges: #{ChaosUtils.decorate(e.src_node.label)} -> #{ChaosUtils.decorate(e.dep_node.label)}")
        # end

        dgraph = ChaosDetector::Graphing::Directed.new(render_path: @render_path)
        dgraph.create_directed_graph(label)
        dgraph.append_nodes(nodes)
        dgraph.add_edges(edges)
        dgraph.render_graph
        dgraph
      end
    end
  end
end
