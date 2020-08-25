require 'chaos_detector/navigator'
require 'chaos_detector/stacker/frame'
require 'chaos_detector/graphing/directed'
require 'chaos_detector/options'
require 'chaos_detector/utils/str_util'
require 'chaos_detector/chaos_utils'

module ChaosDetector
  module Graphing
    class Graphs
      attr_reader :navigator
      attr_reader :chaos_graph

      # TODO: actually use render path from options?
      def initialize(options: nil)
        @options = options || ChaosDetector::Options.new
        @render_path = @options.path_with_root(:graph_render_folder)
        ChaosDetector::Utils::FSUtil::ensure_dirpath(@render_path)
        @navigator = ChaosDetector::Navigator.new(options: @options)
      end

      def playback()
        fn_graph = @navigator.playback()
        @chaos_graph = ChaosDetector::ChaosGraphs::ChaosGraph.new(fn_graph)
        @chaos_graph.infer_all
      end

      def render_mod_dep()
        dgraph = ChaosDetector::Graphing::Directed.new(render_path: @render_path)
        dgraph.create_directed_graph("module-dep")

        dgraph.append_nodes(chaos_graph.module_nodes)

        chaos_graph.module_nodes.each do |n|
          p("ModNode: #{ChaosUtils::decorate(n.label)}")
        end

        chaos_graph.module_edges.each do |e|
          p("ModEdge: #{ChaosUtils::decorate(e.src_node.label)} -> #{ChaosUtils::decorate(e.dep_node.label)}")
        end
        dgraph.add_edges(chaos_graph.module_edges)

        dgraph.render_graph

      end
    end
  end
end
