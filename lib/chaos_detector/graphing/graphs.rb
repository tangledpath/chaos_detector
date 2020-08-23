require 'chaos_detector/atlas'
require 'chaos_detector/navigator'
require 'chaos_detector/stacker/frame'
require 'chaos_detector/graphing/directed'
require 'chaos_detector/options'
require 'tcs/utils/str_util'
require 'tcs/refined_utils'
using TCS::RefinedUtils

module ChaosDetector
  module Graphing
    class Graphs
      attr_reader :atlas
      attr_reader :navigator
      attr_reader :chaos_graph

      # TODO: actually use render path from options?
      def initialize(options: nil)
        @options = options || ChaosDetector::Options.new
        @render_path = @options.path_with_root(:graph_render_folder)
        TCS::Utils::FSUtil::ensure_dirpath(@render_path)
        @navigator = ChaosDetector::Navigator.new(options: @options)
      end

      def playback()
        @atlas = @navigator.playback()
        @chaos_graph = ChaosDetector::ChaosGraphs::ChaosGraph.new(@atlas.graph)
        @chaos_graph.infer_all
      end

      def render_mod_dep()
        dgraph = ChaosDetector::Graphing::Directed.new(render_path: @render_path)
        dgraph.create_directed_graph("module-dep")

        dgraph.append_nodes(chaos_graph.module_nodes)

        chaos_graph.module_nodes.each do |n|
          p("ModNode: #{decorate(n.label)}")
        end

        chaos_graph.module_edges.each do |e|
          p("ModEdge: #{decorate(e.src_node.class)} -> #{decorate(e.dep_node.class)}")
        end
        dgraph.add_edges(chaos_graph.module_edges)

        # dgraph.add_nodes(atlas.nodes)
        # dgraph.add_nodes(atlas.nodes)
        dgraph.render_graph

      end
    end
  end
end
